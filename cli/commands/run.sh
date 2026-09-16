#!/usr/bin/env bash
source "$MASTEROPS_HOME/cli/lib/common.sh"

SERVICE_NAME="${1:-}"
[[ -z "$SERVICE_NAME" ]] && mops_die "usage: masterops start <service>"

COMPOSE_FILE="$PWD/docker-compose.yml"
[[ -f "$COMPOSE_FILE" ]] || mops_die "no docker-compose.yml found in $PWD — run this from inside a project created by 'masterops new'"


if ! grep -qE "^\s{2}${SERVICE_NAME}:" "$COMPOSE_FILE"; then
  mops_die "service '$SERVICE_NAME' not found in docker-compose.yml"
fi


if ! mops_confirm "Start '$SERVICE_NAME' now? This will run: docker compose up -d $SERVICE_NAME"; then
  mops_log "cancelled."
  exit 0
fi

mops_log "starting $SERVICE_NAME..."

if docker compose -f "$COMPOSE_FILE" up -d "$SERVICE_NAME"; then
  mops_ok "$SERVICE_NAME is up."
  mops_log "check status: docker compose ps"
  mops_log "check logs:   docker compose logs -f $SERVICE_NAME"
else
  mops_die "failed to start $SERVICE_NAME — check the error above"
fi



