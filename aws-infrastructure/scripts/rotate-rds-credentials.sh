#!/usr/bin/env bash

set -Eeuo pipefail

region="eu-central-1"
db_instance_identifier="yevmiye-postgres"

get_db_state() {
  aws rds describe-db-instances \
    --region "$region" \
    --db-instance-identifier "$db_instance_identifier" \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text
}

wait_for_db_state() {
  local expected_state="$1"
  local current_state

  for ((attempt = 1; attempt <= 120; attempt++)); do
    current_state="$(get_db_state)"
    if [[ $current_state == "$expected_state" ]]; then
      printf 'PostgreSQL reached %s.\n' "$expected_state"
      return 0
    fi

    printf 'PostgreSQL state: %s; waiting for %s...\n' "$current_state" "$expected_state"
    sleep 15
  done

  printf 'Timed out waiting for PostgreSQL to reach %s.\n' "$expected_state" >&2
  return 1
}

get_current_secret_version() {
  local secret_arn="$1"

  aws secretsmanager list-secret-version-ids \
    --secret-id "$secret_arn" \
    --region "$region" \
    --query 'Versions[?contains(VersionStages, `AWSCURRENT`)].VersionId | [0]' \
    --output text
}

initial_state="$(get_db_state)"
printf 'PostgreSQL instance: %s\n' "$db_instance_identifier"
printf 'Current state: %s\n' "$initial_state"
printf 'AWS will generate a new master password and update the existing Secrets Manager secret.\n'
read -r -p 'Type ROTATE to continue: ' confirmation

if [[ $confirmation != "ROTATE" ]]; then
  printf 'Cancelled.\n'
  exit 0
fi

restore_stopped_state=false

case "$initial_state" in
  stopped)
    restore_stopped_state=true
    ;;
  stopping)
    restore_stopped_state=true
    wait_for_db_state stopped
    ;;
  available)
    ;;
  starting)
    wait_for_db_state available
    ;;
  *)
    printf 'Cannot safely rotate credentials while PostgreSQL is in state: %s\n' "$initial_state" >&2
    exit 1
    ;;
esac

if [[ $(get_db_state) == "stopped" ]]; then
  printf 'Temporarily starting PostgreSQL for credential rotation...\n'
  aws rds start-db-instance \
    --region "$region" \
    --db-instance-identifier "$db_instance_identifier" >/dev/null
  wait_for_db_state available
fi

secret_arn="$(aws rds describe-db-instances \
  --region "$region" \
  --db-instance-identifier "$db_instance_identifier" \
  --query 'DBInstances[0].MasterUserSecret.SecretArn' \
  --output text)"

if [[ -z $secret_arn || $secret_arn == "None" ]]; then
  printf 'RDS does not report a managed master-user secret. Rotation was not attempted.\n' >&2
  exit 1
fi

previous_version="$(get_current_secret_version "$secret_arn")"

printf 'Requesting immediate RDS-managed password rotation...\n'
aws rds modify-db-instance \
  --region "$region" \
  --db-instance-identifier "$db_instance_identifier" \
  --rotate-master-user-password \
  --apply-immediately >/dev/null

rotation_verified=false
for ((attempt = 1; attempt <= 120; attempt++)); do
  current_version="$(get_current_secret_version "$secret_arn")"
  current_state="$(get_db_state)"

  if [[ $current_version != "$previous_version" && $current_state == "available" ]]; then
    rotation_verified=true
    break
  fi

  printf 'Rotation in progress; PostgreSQL state: %s...\n' "$current_state"
  sleep 10
done

if [[ $rotation_verified != true ]]; then
  printf 'Could not verify a new AWSCURRENT secret version. PostgreSQL was left running for investigation.\n' >&2
  exit 1
fi

printf 'Credential rotation verified. The password was not displayed.\n'

if [[ $restore_stopped_state == true ]]; then
  printf 'Returning PostgreSQL to its original stopped state...\n'
  aws rds stop-db-instance \
    --region "$region" \
    --db-instance-identifier "$db_instance_identifier" >/dev/null
  wait_for_db_state stopped
fi

printf 'RDS credential rotation complete.\n'
