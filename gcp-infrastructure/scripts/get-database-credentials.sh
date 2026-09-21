#!/usr/bin/env bash
set -euo pipefail

project_id="${GCP_PROJECT_ID:-yomye-507522}"
parameter_location="${GCP_PARAMETER_LOCATION:-global}"

for command in gcloud curl jq base64; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Missing required command: $command" >&2
    exit 1
  }
done

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

gcloud secrets versions access latest \
  --project="$project_id" \
  --secret="$database_secret_id" \
  | jq -e '{host, port, dbname, username, password}'
