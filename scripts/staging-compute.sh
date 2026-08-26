#!/usr/bin/env bash

set -Eeuo pipefail

region="eu-central-1"
app_instance_names="yevmiye-core-chat,yevmiye-worker"
nat_instance_name="yevmiye-nat"
db_instance_identifier="yevmiye-postgres"

usage() {
  printf 'Usage: %s {start|stop|status}\n' "$0" >&2
  exit 2
}

find_instance_ids() {
  local names="$1"

  aws ec2 describe-instances \
    --region "$region" \
    --filters \
      "Name=tag:Name,Values=${names}" \
      "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text
}

read_instance_ids() {
  local names="$1"
  local -n destination="$2"
  local output

  output="$(find_instance_ids "$names")"
  if [[ -n $output && $output != "None" ]]; then
    read -r -a destination <<< "$output"
  else
    destination=()
  fi
}

require_instances() {
  local label="$1"
  shift

  if (( $# == 0 )); then
    printf 'No %s instances were found in %s.\n' "$label" "$region" >&2
    exit 1
  fi
}

wait_for_db_state() {
  local expected_state="$1"
  local current_state
  local elapsed_seconds

  for ((attempt = 1; attempt <= 120; attempt++)); do
    current_state="$(aws rds describe-db-instances \
      --region "$region" \
      --db-instance-identifier "$db_instance_identifier" \
      --query 'DBInstances[0].DBInstanceStatus' \
      --output text)"

    if [[ $current_state == "$expected_state" ]]; then
      elapsed_seconds=$(((attempt - 1) * 15))
      printf 'PostgreSQL reached %s after %s seconds.\n' "$expected_state" "$elapsed_seconds"
      return 0
    fi

    elapsed_seconds=$(((attempt - 1) * 15))
    printf 'PostgreSQL state: %s; waiting for %s (%ss elapsed)...\n' \
      "$current_state" "$expected_state" "$elapsed_seconds"
    sleep 15
  done

  printf 'Timed out waiting for PostgreSQL to reach %s.\n' "$expected_state" >&2
  return 1
}

start_instances() {
  local -a nat_ids app_ids
  local db_state
  read_instance_ids "$nat_instance_name" nat_ids
  read_instance_ids "$app_instance_names" app_ids
  require_instances 'NAT' "${nat_ids[@]}"
  require_instances 'application' "${app_ids[@]}"

  db_state="$(aws rds describe-db-instances \
    --region "$region" \
    --db-instance-identifier "$db_instance_identifier" \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text)"

  case "$db_state" in
    stopped)
      printf 'Starting PostgreSQL...\n'
      aws rds start-db-instance \
        --region "$region" \
        --db-instance-identifier "$db_instance_identifier" >/dev/null
      ;;
    starting)
      printf 'PostgreSQL is already starting...\n'
      ;;
    available)
      printf 'PostgreSQL is already running.\n'
      ;;
    *)
      printf 'PostgreSQL cannot be started from state: %s\n' "$db_state" >&2
      exit 1
      ;;
  esac

  aws rds wait db-instance-available \
    --region "$region" \
    --db-instance-identifier "$db_instance_identifier"

  printf 'Starting NAT instance...\n'
  aws ec2 start-instances \
    --region "$region" \
    --instance-ids "${nat_ids[@]}" >/dev/null
  aws ec2 wait instance-status-ok \
    --region "$region" \
    --instance-ids "${nat_ids[@]}"
  printf 'NAT instance is running: %s\n' "${nat_ids[*]}"

  printf 'Starting Core/Chat and Worker instances...\n'
  aws ec2 start-instances \
    --region "$region" \
    --instance-ids "${app_ids[@]}" >/dev/null
  aws ec2 wait instance-status-ok \
    --region "$region" \
    --instance-ids "${app_ids[@]}"
  printf 'Core/Chat and Worker instances are running: %s\n' "${app_ids[*]}"

  printf 'Staging EC2 and PostgreSQL are running.\n'
}

stop_instances() {
  local -a nat_ids app_ids
  local db_state
  read_instance_ids "$nat_instance_name" nat_ids
  read_instance_ids "$app_instance_names" app_ids
  require_instances 'NAT' "${nat_ids[@]}"
  require_instances 'application' "${app_ids[@]}"

  printf 'Stopping Core/Chat and Worker instances...\n'
  aws ec2 stop-instances \
    --region "$region" \
    --instance-ids "${app_ids[@]}" >/dev/null
  aws ec2 wait instance-stopped \
    --region "$region" \
    --instance-ids "${app_ids[@]}"
  printf 'Core/Chat and Worker instances are stopped: %s\n' "${app_ids[*]}"

  printf 'Stopping NAT instance...\n'
  aws ec2 stop-instances \
    --region "$region" \
    --instance-ids "${nat_ids[@]}" >/dev/null
  aws ec2 wait instance-stopped \
    --region "$region" \
    --instance-ids "${nat_ids[@]}"
  printf 'NAT instance is stopped: %s\n' "${nat_ids[*]}"

  db_state="$(aws rds describe-db-instances \
    --region "$region" \
    --db-instance-identifier "$db_instance_identifier" \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text)"

  case "$db_state" in
    available)
      printf 'Stopping PostgreSQL; its data storage will be retained. This can take several minutes...\n'
      aws rds stop-db-instance \
        --region "$region" \
        --db-instance-identifier "$db_instance_identifier" >/dev/null
      ;;
    stopping)
      printf 'PostgreSQL is already stopping. This can take several minutes...\n'
      ;;
    stopped)
      printf 'PostgreSQL is already stopped.\n'
      ;;
    *)
      printf 'PostgreSQL cannot be stopped from state: %s\n' "$db_state" >&2
      exit 1
      ;;
  esac

  wait_for_db_state stopped

  printf 'Staging EC2 and PostgreSQL are stopped. PostgreSQL data is retained.\n'
}

show_status() {
  printf 'EC2 instances:\n'
  aws ec2 describe-instances \
    --region "$region" \
    --filters \
      "Name=tag:Name,Values=${app_instance_names},${nat_instance_name}" \
      "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,InstanceId:InstanceId,State:State.Name}' \
    --output table

  printf '\nPostgreSQL:\n'
  aws rds describe-db-instances \
    --region "$region" \
    --db-instance-identifier "$db_instance_identifier" \
    --query 'DBInstances[].{Identifier:DBInstanceIdentifier,State:DBInstanceStatus,Engine:Engine}' \
    --output table
}

case "${1:-}" in
  start)
    start_instances
    ;;
  stop)
    stop_instances
    ;;
  status)
    show_status
    ;;
  *)
    usage
    ;;
esac
