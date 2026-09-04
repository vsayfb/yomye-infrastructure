#!/usr/bin/env bash

set -e

if ! command -v gcloud >/dev/null 2>&1; then
  printf 'gcloud is required.\n' >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'jq is required to validate Firebase credentials.\n' >&2
  exit 1
fi

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
START_AT="${START_AT:-}"
reached_start=false

if [[ -z $PROJECT_ID || $PROJECT_ID == "(unset)" ]]; then
  printf 'Set a gcloud project or pass the project ID as the first argument.\n' >&2
  exit 1
fi

should_prompt() {
  local label="$1"

  if [[ -z $START_AT ]]; then
    return 0
  fi
  if [[ $label == "$START_AT" ]]; then
    reached_start=true
  fi

  [[ $reached_start == true ]]
}

put_secret() {
  local parameter_name="$1"
  local label="$2"
  local value
  local version_id

  should_prompt "$label" || return 0

  read -r -s -p "Enter ${label} (leave empty to skip): " value
  printf '\n'

  if [[ -z $value ]]; then
    printf 'Skipped %s.\n\n' "$parameter_name"
    return 0
  fi

  version_id="manual-$(date -u +%Y%m%d%H%M%S)-${RANDOM}"
  printf '%s' "$value" \
    | gcloud parametermanager parameters versions create "$version_id" \
      --parameter "$parameter_name" \
      --project "$PROJECT_ID" \
      --location global \
      --payload-data-from-file /dev/stdin >/dev/null

  unset value
  printf 'Stored %s.\n\n' "$parameter_name"
}

put_firebase_credentials() {
  local parameter_name="firebase-credentials"
  local credentials_path
  local credentials_json
  local version_id

  should_prompt "FIREBASE_CREDENTIALS_PATH" || return 0

  while true; do
    read -r -p 'Enter FIREBASE_CREDENTIALS_PATH (leave empty to skip): ' credentials_path

    if [[ -z $credentials_path ]]; then
      printf 'Skipped %s.\n\n' "$parameter_name"
      return 0
    fi

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
  if ! printf '%s' "$credentials_json" | jq -e . >/dev/null; then
    printf 'Firebase credentials file is not valid JSON.\n' >&2
    exit 1
  fi

  version_id="manual-$(date -u +%Y%m%d%H%M%S)-${RANDOM}"
  printf '%s' "$credentials_json" \
    | gcloud parametermanager parameters versions create "$version_id" \
      --parameter "$parameter_name" \
      --project "$PROJECT_ID" \
      --location global \
      --payload-data-from-file /dev/stdin >/dev/null

  unset credentials_json
  printf 'Stored %s.\n\n' "$parameter_name"
}

printf 'Populating Parameter Manager in project %s.\n\n' "$PROJECT_ID"

put_secret "otlp-auth-token" "OPAMP_AUTH_TOKEN"
put_secret "otlp-write-key" "OTLP_WRITE_KEY"
put_firebase_credentials
put_secret "jwt-secret" "JWT_SECRET"
put_secret "mongo-db-uri" "MONGO_DB_URI"
put_secret "groq-api-key" "GROQ_API_KEY"
put_secret "gemini-api-key" "GEMINI_API_KEY"
put_secret "open-router-api-key" "OPEN_ROUTER_API_KEY"
put_secret "nvidia-api-key" "NVIDIA_API_KEY"
put_secret "mistral-api-key" "MISTRAL_API_KEY"
put_secret "cloudinary-api-secret" "CLOUDINARY_API_SECRET"

if [[ -n $START_AT && $reached_start == false ]]; then
  printf 'Unknown START_AT value: %s\n' "$START_AT" >&2
  exit 1
fi

printf 'All manually managed parameters were populated.\n'
