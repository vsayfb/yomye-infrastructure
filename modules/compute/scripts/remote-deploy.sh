#!/bin/bash
set -euo pipefail

: "${SERVICE_NAME:?SERVICE_NAME is required}"
: "${BINARY_NAME:?BINARY_NAME is required}"
: "${S3_BUCKET:?S3_BUCKET is required}"
: "${S3_KEY:?S3_KEY is required}"

APP_DIR="/opt/app/${SERVICE_NAME}"
RELEASE_DIR="${APP_DIR}/releases/$(date +%Y%m%d%H%M%S)"
CURRENT_LINK="${APP_DIR}/current"
PREVIOUS_LINK="${APP_DIR}/previous"
UNIT_NAME="${SERVICE_NAME}.service"
BINARY_PATH="${RELEASE_DIR}/${BINARY_NAME}"
S3_URI="s3://${S3_BUCKET}/${S3_KEY}"

echo "Deploying ${SERVICE_NAME}"
echo "Artifact: ${S3_URI}"
echo "Release: ${RELEASE_DIR}"

mkdir -p "${RELEASE_DIR}"

aws s3 cp "${S3_URI}" "${BINARY_PATH}"
chmod +x "${BINARY_PATH}"

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
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${CURRENT_LINK}
ExecStart=${CURRENT_LINK}/${BINARY_NAME}

Environment=APP_ENV=staging
Environment=AWS_REGION=eu-central-1
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
    echo "${UNIT_NAME} failed to start"
    systemctl status "${UNIT_NAME}" --no-pager -l || true
    journalctl -u "${UNIT_NAME}" --no-pager -n 100 || true
    exit 1
fi

echo "${SERVICE_NAME} deployed successfully"