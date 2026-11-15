#!/usr/bin/env bash

set -euo pipefail

parameter_prefix=/yevmiye/staging
credentials=(
  'otlp-auth-token|Grafana OpAMP authorization value'
  'otlp-write-key|Grafana Cloud OTLP write key'
  'firebase-credentials|path to the Firebase credentials JSON file'
  'jwt-secret|JWT signing secret'
  'mongo-db-uri|MongoDB connection URI'
  'groq-api-key|Groq API key'
  'gemini-api-key|Gemini API key'
  'geonames-username|GEONAMES_USERNAME'
  'open-router-api-key|OpenRouter API key'
  'nvidia-api-key|NVIDIA API key'
  'mistral-api-key|Mistral API key'
  'qwen-api-key|Qwen API key'
  'cloudinary-api-secret|Cloudinary API secret'
)

usage() {
  printf 'Usage: %s [CREDENTIAL]\n' "${0##*/}"
  printf 'With no argument, prompt for all staging credentials. Press Enter to skip any prompt.\n'
  printf 'Providing a value creates or replaces that SecureString in eu-central-1.\n\n'
  printf 'Credentials:\n'
  local entry
  for entry in "${credentials[@]}"; do
    printf '  %s\n' "${entry%%|*}"
  done
}

put_credential() {
  local key="$1" label="$2"
  local parameter_name="$parameter_prefix/$key"
  local value path

  if [[ "$key" == firebase-credentials ]]; then
    while true; do
      IFS= read -r -p "Enter $label (Enter to skip): " path
      if [[ -z "$path" ]]; then
        printf 'Skipped %s.\n' "$parameter_name"
        return
      fi
      if [[ -f "$path" && -r "$path" && -s "$path" ]]; then
        value="$(<"$path")"
        if [[ -n "$value" ]]; then
          break
        fi
      fi
      printf 'Provide a readable, nonempty Firebase credentials file.\n' >&2
    done
  else
    IFS= read -r -s -p "Enter $label (Enter to skip): " value
    printf '\n'
    if [[ -z "$value" ]]; then
      printf 'Skipped %s.\n' "$parameter_name"
      return
    fi
  fi

  printf '%s' "$value" | aws ssm put-parameter \
    --region eu-central-1 \
    --name "$parameter_name" \
    --value file:///dev/stdin \
    --type SecureString \
    --overwrite \
    --no-cli-pager
  printf 'Stored %s.\n' "$parameter_name"
}

if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  usage
  exit 0
fi
if (( $# > 1 )); then
  usage >&2
  exit 2
fi

selected="${1:-}"
for entry in "${credentials[@]}"; do
  key="${entry%%|*}"
  if [[ -z "$selected" || "$selected" == "$key" ]]; then
    put_credential "$key" "${entry#*|}"
    if [[ -n "$selected" ]]; then
      exit 0
    fi
  fi
done

if [[ -n "$selected" ]]; then
  printf 'Unknown credential: %s\n' "$selected" >&2
  usage >&2
  exit 2
fi
