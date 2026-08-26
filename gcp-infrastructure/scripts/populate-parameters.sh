#!/bin/bash
set -euo pipefail

if ! command -v gcloud >/dev/null 2>&1; then
    echo "gcloud is required." >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to validate Firebase credentials." >&2
    exit 1
fi

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "Set a gcloud project or pass the project ID as the first argument." >&2
    exit 1
fi

add_text_parameter() {
    local parameter_name="$1"
    local label="$2"
    local value
    local version_id

    if ! gcloud parametermanager parameters describe "$parameter_name" \
        --project "$PROJECT_ID" \
        --location global >/dev/null 2>&1; then
        echo "Parameter $parameter_name does not exist; apply Terraform first." >&2
        exit 1
    fi

    while true; do
        read -r -s -p "Enter ${label}: " value
        echo
        [ -n "$value" ] && break
        echo "Value cannot be empty."
    done

    version_id="manual-$(date -u +%Y%m%d%H%M%S)-${RANDOM}"
    printf '%s' "$value" \
        | gcloud parametermanager parameters versions create "$version_id" \
            --parameter "$parameter_name" \
            --project "$PROJECT_ID" \
            --location global \
            --payload-data-from-file /dev/stdin >/dev/null
    unset value
    echo "Added a new version to $parameter_name."
}

add_firebase_credentials() {
    local parameter_name="firebase-credentials"
    local credentials_path
    local version_id

    if ! gcloud parametermanager parameters describe "$parameter_name" \
        --project "$PROJECT_ID" \
        --location global >/dev/null 2>&1; then
        echo "Parameter $parameter_name does not exist; apply Terraform first." >&2
        exit 1
    fi

    while true; do
        read -r -p "Enter the path to the Firebase credentials JSON file: " credentials_path
        [ -f "$credentials_path" ] && [ -r "$credentials_path" ] && break
        echo "File does not exist or is not readable: $credentials_path" >&2
    done

    if ! jq -e . "$credentials_path" >/dev/null; then
        echo "$credentials_path is not valid JSON." >&2
        exit 1
    fi

    version_id="manual-$(date -u +%Y%m%d%H%M%S)-${RANDOM}"
    gcloud parametermanager parameters versions create "$version_id" \
        --parameter "$parameter_name" \
        --project "$PROJECT_ID" \
        --location global \
        --payload-data-from-file "$credentials_path" >/dev/null
    echo "Added the file as a new version of $parameter_name."
}

echo "Populating Parameter Manager in project $PROJECT_ID."
echo "Typed values are hidden and passed through stdin, not command arguments."

add_text_parameter "otlp-auth-token" "Grafana OpAMP authorization value"
add_text_parameter "otlp-write-key" "Grafana Cloud OTLP write key"
add_firebase_credentials
add_text_parameter "jwt-secret" "JWT signing secret"
add_text_parameter "mongo-db-uri" "MongoDB connection URI"
add_text_parameter "groq-api-key" "Groq API key"
add_text_parameter "gemini-api-key" "Gemini API key"
add_text_parameter "open_router-api-key" "OpenRouter API key"
add_text_parameter "nvidia-api-key" "NVIDIA API key"
add_text_parameter "mistral-api-key" "Mistral API key"
add_text_parameter "cloudinary-api-secret" "Cloudinary API secret"

echo "All manually managed production parameters were populated."
