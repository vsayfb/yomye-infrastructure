#!/bin/bash
set -euo pipefail

: "${SERVICE_NAME:?SERVICE_NAME is required}"
: "${BINARY_NAME:?BINARY_NAME is required}"
: "${GCS_BUCKET:?GCS_BUCKET is required}"
: "${GCS_OBJECT:?GCS_OBJECT is required}"

APP_ENV="${APP_ENV:-production}"
GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT:-$(curl -fsS -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/project/project-id)}"
PARAMETER_LOCATION="${PARAMETER_LOCATION:-global}"
APP_DIR="/opt/app/${SERVICE_NAME}"
RELEASE_DIR="${APP_DIR}/releases/$(date +%Y%m%d%H%M%S)"
CURRENT_LINK="${APP_DIR}/current"
PREVIOUS_LINK="${APP_DIR}/previous"
UNIT_NAME="${SERVICE_NAME}.service"
BINARY_PATH="${RELEASE_DIR}/${BINARY_NAME}"
GCS_URI="gs://${GCS_BUCKET}/${GCS_OBJECT}"

echo "Deploying ${SERVICE_NAME} from ${GCS_URI}"
mkdir -p "${RELEASE_DIR}"

gcloud storage cp "${GCS_URI}" "${BINARY_PATH}"
chmod 0755 "${BINARY_PATH}"

if [ -L "${CURRENT_LINK}" ]; then
    CURRENT_RELEASE="$(readlink -f "${CURRENT_LINK}" || true)"
    if [ -n "${CURRENT_RELEASE}" ]; then
        ln -sfn "${CURRENT_RELEASE}" "${PREVIOUS_LINK}"
    fi
fi

ln -sfn "${RELEASE_DIR}" "${CURRENT_LINK}"

cat >"/etc/systemd/system/${UNIT_NAME}" <<UNIT
[Unit]
Description=Yevmiye ${SERVICE_NAME}
After=network-online.target otel-supervisor.service
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${CURRENT_LINK}
ExecStart=${CURRENT_LINK}/${BINARY_NAME}
Environment=APP_ENV=${APP_ENV}
Environment=GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}
Environment=GCP_PARAMETER_LOCATION=${PARAMETER_LOCATION}
Environment=OTEL_COLLECTOR_ADDR=localhost:4317
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable "${UNIT_NAME}"
systemctl restart "${UNIT_NAME}"
sleep 3

if ! systemctl is-active --quiet "${UNIT_NAME}"; then
    systemctl status "${UNIT_NAME}" --no-pager -l || true
    journalctl -u "${UNIT_NAME}" --no-pager -n 100 || true
    exit 1
fi

echo "${SERVICE_NAME} deployed successfully"
