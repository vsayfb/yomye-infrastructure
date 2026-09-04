#!/bin/bash
set -euo pipefail

SERVICE_NAME="${service_name}"
APP_ENV="${environment}"
OTLP_ENDPOINT="${grafana_cloud_otlp_endpoint}"
PROJECT_ID="$(curl -fsS -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/project/project-id)"

parameter_value() {
    local parameter_name="$1"
    local access_token

    access_token="$(gcloud auth print-access-token)"
    curl -fsS \
        -H "Authorization: Bearer $access_token" \
        "https://parametermanager.googleapis.com/v1/projects/$${PROJECT_ID}/locations/global/parameters/$${parameter_name}/versions/latest:render" \
        | jq -er '.renderedPayload' \
        | base64 -d
}

set +x
OPAMP_ENDPOINT="$(parameter_value grafana-cloud-opamp-endpoint)"
OPAMP_AUTH_TOKEN="$(parameter_value otlp-auth-token)"
OTLP_WRITE_KEY="$(parameter_value otlp-write-key)"
OPAMP_ENDPOINT="$${OPAMP_ENDPOINT%/}"
OPAMP_ENDPOINT="$${OPAMP_ENDPOINT%/v1/opamp}"

umask 077
cat >/opt/otel/supervisor.yaml <<EOF_SUPERVISOR
server:
  endpoint: "$OPAMP_ENDPOINT/v1/opamp"
  headers:
    Authorization: "Basic $OPAMP_AUTH_TOKEN"

capabilities:
  reports_effective_config: true
  accepts_remote_config: true
  reports_remote_config: true

agent:
  executable: /opt/otel/bin/otelcontribcol_linux_amd64
  description:
    identifying_attributes:
      service.name: "$SERVICE_NAME"
      deployment.environment.name: "$APP_ENV"
  args:
    - --feature-gates
    - service.AllowNoPipelines
  env:
    GCLOUD_FM_URL: "$OPAMP_ENDPOINT"
    GCLOUD_BASIC_AUTH_BASE64: "$OPAMP_AUTH_TOKEN"
    GCLOUD_RW_API_KEY: "$OTLP_WRITE_KEY"
    GCLOUD_OTLP_ENDPOINT: "$OTLP_ENDPOINT"

storage:
  directory: /opt/otel/storage
EOF_SUPERVISOR
chmod 0600 /opt/otel/supervisor.yaml
unset OPAMP_AUTH_TOKEN OTLP_WRITE_KEY

systemctl enable --now otel-supervisor.service
