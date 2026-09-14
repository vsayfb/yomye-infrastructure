#!/usr/bin/env bash
set -euo pipefail

project_id="${GCP_PROJECT_ID:-yomye-507522}"
zone="${GCP_ZONE:-europe-west3-a}"
instance_name="${GCP_CORE_CHAT_INSTANCE:-}"
local_host="${POSTGRES_LOCAL_HOST:-0.0.0.0}"
local_port="${POSTGRES_LOCAL_PORT:-5432}"
parameter_location="${GCP_PARAMETER_LOCATION:-global}"

for command in gcloud curl jq base64; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Missing required command: $command" >&2
    exit 1
  }
done

if command -v ss >/dev/null 2>&1 && ss -ltnH "sport = :$local_port" | grep -q .; then
  echo "$local_host:$local_port is already in use." >&2
  exit 1
fi

access_token="$(gcloud auth print-access-token)"
parameter_url="https://parametermanager.googleapis.com/v1/projects/${project_id}/locations/${parameter_location}/parameters/rds-secret-arn/versions/latest:render"
database_secret_resource="$(
  curl -fsS \
    -H "Authorization: Bearer $access_token" \
    "$parameter_url" \
    | jq -er '.renderedPayload' \
    | base64 -d
)"
database_secret_id="${database_secret_resource##*/}"

database_json="$(
  gcloud secrets versions access latest \
    --project="$project_id" \
    --secret="$database_secret_id"
)"
database_host="$(jq -er '.host' <<<"$database_json")"
database_port="$(jq -er '.port' <<<"$database_json")"
database_name="$(jq -er '.dbname' <<<"$database_json")"
database_user="$(jq -er '.username' <<<"$database_json")"

if [[ -z "$instance_name" ]]; then
  mapfile -t core_chat_instances < <(
    gcloud compute instances list \
      --project="$project_id" \
      --filter="zone:($zone) AND name~'-core-chat$' AND status=RUNNING" \
      --format='value(name)'
  )
  if [[ "${#core_chat_instances[@]}" -ne 1 ]]; then
    echo "Expected exactly one running instance ending in -core-chat in $zone; found ${#core_chat_instances[@]}." >&2
    echo "Set GCP_CORE_CHAT_INSTANCE explicitly and retry." >&2
    exit 1
  fi
  instance_name="${core_chat_instances[0]}"
fi

echo "Opening PostgreSQL tunnel through $instance_name."
echo "Local endpoint: postgresql://${database_user}@${local_host}:${local_port}/${database_name}"
echo "Keep this process running; press Ctrl+C to close the tunnel."

exec gcloud compute ssh "$instance_name" \
  --project="$project_id" \
  --zone="$zone" \
  --tunnel-through-iap \
  -- -N -L "${local_host}:${local_port}:${database_host}:${database_port}"
