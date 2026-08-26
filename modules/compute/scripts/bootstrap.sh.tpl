#!/bin/bash
set -euxo pipefail

AWS_REGION="${aws_region}"
OPAMP_ENDPOINT_PARAMETER_NAME="${opamp_endpoint_parameter_name}"
OPAMP_AUTH_TOKEN_PARAMETER_NAME="${opamp_auth_token_parameter_name}"
OTLP_WRITE_KEY_PARAMETER_NAME="${otlp_write_key_parameter_name}"
OTLP_ENDPOINT="${grafana_cloud_otlp_endpoint}"
OTEL_COLLECTOR_VERSION="${otel_collector_version}"
SERVICE_NAME="${service_name}"

dnf install -y unzip tar

if ! command -v aws >/dev/null 2>&1; then
    curl -fsSL \
        "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
        -o /tmp/awscliv2.zip

    rm -rf /tmp/aws
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install

    rm -rf /tmp/aws /tmp/awscliv2.zip
fi

set +x

OPAMP_ENDPOINT=$(
    aws ssm get-parameter \
        --region "$AWS_REGION" \
        --name "$OPAMP_ENDPOINT_PARAMETER_NAME" \
        --query "Parameter.Value" \
        --output text
)

OPAMP_AUTH_TOKEN=$(
    aws ssm get-parameter \
        --region "$AWS_REGION" \
        --name "$OPAMP_AUTH_TOKEN_PARAMETER_NAME" \
        --with-decryption \
        --query "Parameter.Value" \
        --output text
)

OTLP_WRITE_KEY=$(
    aws ssm get-parameter \
        --region "$AWS_REGION" \
        --name "$OTLP_WRITE_KEY_PARAMETER_NAME" \
        --with-decryption \
        --query "Parameter.Value" \
        --output text
)

set -x

mkdir -p /opt/otel/bin /opt/otel/storage

curl -fsSL \
    "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v$${OTEL_COLLECTOR_VERSION}/otelcol-contrib_$${OTEL_COLLECTOR_VERSION}_linux_amd64.tar.gz" \
    -o /tmp/otelcol-contrib.tar.gz

tar -xzf /tmp/otelcol-contrib.tar.gz \
    -C /opt/otel/bin \
    otelcol-contrib

mv \
    /opt/otel/bin/otelcol-contrib \
    /opt/otel/bin/otelcontribcol_linux_amd64

chmod +x /opt/otel/bin/otelcontribcol_linux_amd64
rm -f /tmp/otelcol-contrib.tar.gz

curl -fsSL \
    "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/cmd/opampsupervisor/v$${OTEL_COLLECTOR_VERSION}/opampsupervisor_$${OTEL_COLLECTOR_VERSION}_linux_amd64" \
    -o /opt/otel/bin/opampsupervisor

chmod +x /opt/otel/bin/opampsupervisor

cat >/opt/otel/supervisor.yaml <<EOF
server:
  endpoint: "$${OPAMP_ENDPOINT%/}/v1/opamp"
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
EOF

cat >/etc/systemd/system/otel-supervisor.service <<'EOF'
[Unit]
Description=OpenTelemetry OpAMP Supervisor
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/opt/otel/bin/opampsupervisor --config=/opt/otel/supervisor.yaml
WorkingDirectory=/opt/otel
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable otel-supervisor
systemctl restart otel-supervisor

mkdir -p /opt/deploy

echo '${remote_deploy_script_b64}' | base64 -d >/opt/deploy/remote-deploy.sh

chmod +x /opt/deploy/remote-deploy.sh

echo "Bootstrap installation complete."
