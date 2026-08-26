#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
SERVICE_NAME="${service_name}"
OTEL_COLLECTOR_VERSION="${otel_collector_version}"

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg jq tar unzip

install -m 0755 -d /usr/share/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    >/etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update
apt-get install -y google-cloud-cli

mkdir -p /opt/otel/bin /opt/otel/storage
curl -fsSL \
    "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v$${OTEL_COLLECTOR_VERSION}/otelcol-contrib_$${OTEL_COLLECTOR_VERSION}_linux_amd64.tar.gz" \
    -o /tmp/otelcol-contrib.tar.gz
tar -xzf /tmp/otelcol-contrib.tar.gz -C /opt/otel/bin otelcol-contrib
mv /opt/otel/bin/otelcol-contrib /opt/otel/bin/otelcontribcol_linux_amd64
chmod 0755 /opt/otel/bin/otelcontribcol_linux_amd64
rm -f /tmp/otelcol-contrib.tar.gz

curl -fsSL \
    "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/cmd/opampsupervisor/v$${OTEL_COLLECTOR_VERSION}/opampsupervisor_$${OTEL_COLLECTOR_VERSION}_linux_amd64" \
    -o /opt/otel/bin/opampsupervisor
chmod 0755 /opt/otel/bin/opampsupervisor

cat >/etc/systemd/system/otel-supervisor.service <<'EOF_OTEL_SERVICE'
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
EOF_OTEL_SERVICE

echo '${otel_configure_script_b64}' | base64 -d >/usr/local/bin/configure-otel.sh
chmod 0700 /usr/local/bin/configure-otel.sh

cat >/etc/systemd/system/configure-otel.service <<'EOF_CONFIGURE_SERVICE'
[Unit]
Description=Configure Grafana OpenTelemetry credentials
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/configure-otel.sh
Restart=on-failure
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF_CONFIGURE_SERVICE

mkdir -p /opt/deploy
echo '${remote_deploy_script_b64}' | base64 -d >/opt/deploy/remote-deploy.sh
chmod 0755 /opt/deploy/remote-deploy.sh

systemctl daemon-reload
systemctl enable configure-otel.service
# Credential versions may be populated just after the first apply. This unit
# retries without aborting the rest of the host bootstrap.
systemctl start configure-otel.service || true

%{ if install_ollama ~}
if ! command -v ollama >/dev/null 2>&1; then
    curl -fsSL https://ollama.com/install.sh | sh
fi
systemctl enable --now ollama
for _ in $(seq 1 60); do
    systemctl is-active --quiet ollama && break
    sleep 2
done
systemctl is-active --quiet ollama
OLLAMA_HOME="$(getent passwd ollama | cut -d: -f6)"
sudo -u ollama env HOME="$OLLAMA_HOME" ollama list \
    | awk 'NR > 1 {print $1}' \
    | grep -qx 'all-minilm:l12-v2' \
    || sudo -u ollama env HOME="$OLLAMA_HOME" ollama pull all-minilm:l12-v2
%{ endif ~}

echo "GCP bootstrap complete for $SERVICE_NAME"
