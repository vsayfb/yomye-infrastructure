#!/usr/bin/env bash

set -Eeuo pipefail

source_name="/yevmiye/app/qwen-api-key"
destination_name="/yevmiye/staging/qwen-api-key"
region="eu-central-1"

parameter_type="$(aws ssm get-parameter \
  --name "$source_name" \
  --region "$region" \
  --query 'Parameter.Type' \
  --output text)"

parameter_value="$(aws ssm get-parameter \
  --name "$source_name" \
  --with-decryption \
  --region "$region" \
  --query 'Parameter.Value' \
  --output text)"

printf '%s will be moved to %s.\n' "$source_name" "$destination_name"
read -r -p 'Type MIGRATE to continue: ' confirmation

if [[ $confirmation != "MIGRATE" ]]; then
  unset parameter_value
  printf 'Cancelled.\n'
  exit 0
fi

key_args=()
if [[ $parameter_type == "SecureString" ]]; then
  key_id="$(aws ssm describe-parameters \
    --parameter-filters "Key=Name,Option=Equals,Values=${source_name}" \
    --region "$region" \
    --query 'Parameters[0].KeyId' \
    --output text)"

  if [[ -n $key_id && $key_id != "None" ]]; then
    key_args=(--key-id "$key_id")
  fi
fi

aws ssm put-parameter \
  --name "$destination_name" \
  --value "$parameter_value" \
  --type "$parameter_type" \
  --overwrite \
  --region "$region" \
  "${key_args[@]}" >/dev/null

copied_value="$(aws ssm get-parameter \
  --name "$destination_name" \
  --with-decryption \
  --region "$region" \
  --query 'Parameter.Value' \
  --output text)"

if [[ $copied_value != "$parameter_value" ]]; then
  unset parameter_value copied_value
  printf 'Verification failed. The source parameter was not deleted.\n' >&2
  exit 1
fi

unset parameter_value copied_value

aws ssm delete-parameter \
  --name "$source_name" \
  --region "$region"

printf 'Moved %s to %s and removed the old parameter.\n' "$source_name" "$destination_name"
