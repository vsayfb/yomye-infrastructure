#!/usr/bin/env bash

set -e

put_secret() {
  local parameter_name="$1"
  local label="$2"
  local value

  while [[ -z ${value:-} ]]; do
    read -r -s -p "Enter ${label}: " value
    printf '\n'

    if [[ -z $value ]]; then
      printf 'Value cannot be empty.\n' >&2
    fi
  done

  aws ssm put-parameter \
    --name "$parameter_name" \
    --value "$value" \
    --type SecureString

  unset value
  printf 'Stored %s.\n\n' "$parameter_name"
}

put_firebase_credentials() {
  local parameter_name="/yevmiye/staging/firebase-credentials"
  local credentials_path
  local credentials_json

  while true; do
    read -r -p 'Enter the path to the Firebase credentials JSON file: ' credentials_path

    if [[ -f $credentials_path && -r $credentials_path ]]; then
      break
    fi

    printf 'File does not exist or is not readable: %s\n' "$credentials_path" >&2
  done

  credentials_json="$(<"$credentials_path")"
  if [[ -z $credentials_json ]]; then
    printf 'Firebase credentials file is empty.\n' >&2
    exit 1
  fi

  aws ssm put-parameter \
    --name "$parameter_name" \
    --value "$credentials_json" \
    --type SecureString

  unset credentials_json
  printf 'Stored %s.\n\n' "$parameter_name"
}

put_secret "/yevmiye/staging/otlp-auth-token" "Grafana OpAMP authorization value"
put_secret "/yevmiye/staging/otlp-write-key" "Grafana Cloud OTLP write key"
put_firebase_credentials
put_secret "/yevmiye/staging/jwt-secret" "JWT signing secret"
put_secret "/yevmiye/staging/mongo-db-uri" "MongoDB connection URI"
put_secret "/yevmiye/staging/groq-api-key" "Groq API key"
put_secret "/yevmiye/staging/gemini-api-key" "Gemini API key"
put_secret "/yevmiye/staging/open_router-api-key" "OpenRouter API key"
put_secret "/yevmiye/staging/nvidia-api-key" "NVIDIA API key"
put_secret "/yevmiye/staging/mistral-api-key" "Mistral API key"
put_secret "/yevmiye/staging/cloudinary-api-secret" "Cloudinary API secret"
