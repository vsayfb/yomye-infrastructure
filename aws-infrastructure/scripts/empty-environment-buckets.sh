#!/usr/bin/env bash

set -Eeuo pipefail

region="eu-central-1"

for command_name in aws jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf '%s is required but was not found in PATH.\n' "$command_name" >&2
    exit 1
  fi
done

account_id="$(aws sts get-caller-identity --query Account --output text)"
buckets=(
  "yevmiye-app-deployments-${account_id}"
  "yevmiye-lambda-deployments-${account_id}"
)

printf 'This permanently deletes every object version and delete marker from:\n'
printf '  s3://%s\n' "${buckets[@]}"
printf '\nThe Terraform state bucket yevmiye-bootstrap is deliberately excluded.\n'
read -r -p 'Type WIPE to continue: ' confirmation

if [[ $confirmation != "WIPE" ]]; then
  printf 'Cancelled.\n'
  exit 0
fi

empty_versioned_bucket() {
  local bucket="$1"
  local listing
  local delete_payload
  local object_count

  if ! aws s3api head-bucket --bucket "$bucket" --region "$region" 2>/dev/null; then
    printf 'Bucket does not exist or is inaccessible; skipping s3://%s\n' "$bucket"
    return
  fi

  printf 'Emptying s3://%s ...\n' "$bucket"

  while true; do
    listing="$(aws s3api list-object-versions \
      --bucket "$bucket" \
      --region "$region" \
      --max-items 1000 \
      --output json)"

    delete_payload="$(printf '%s' "$listing" | jq -c '{
      Objects: (
        ((.Versions // []) + (.DeleteMarkers // []))
        | map({Key: .Key, VersionId: .VersionId})
      ),
      Quiet: true
    }')"
    object_count="$(printf '%s' "$delete_payload" | jq '.Objects | length')"

    if (( object_count == 0 )); then
      break
    fi

    aws s3api delete-objects \
      --bucket "$bucket" \
      --region "$region" \
      --delete "$delete_payload" >/dev/null

    printf 'Deleted %s object versions/delete markers.\n' "$object_count"
  done

  printf 'Emptied s3://%s\n' "$bucket"
}

for bucket in "${buckets[@]}"; do
  empty_versioned_bucket "$bucket"
done

printf '\nEnvironment deployment buckets are empty. You can retry terraform destroy.\n'
