#!/usr/bin/env bash
# Shared helpers — sourced by every command, never executed directly.
# Created By MoTarek@DevOpsEngineer

set -euo pipefail

MOPS_BLUE='\033[0;34m'
MOPS_GREEN='\033[0;32m'
MOPS_YELLOW='\033[0;33m'
MOPS_RED='\033[0;31m'
MOPS_RESET='\033[0m'

mops_log()   { echo -e "${MOPS_BLUE}[masterops]${MOPS_RESET} $*"; }
mops_ok()    { echo -e "${MOPS_GREEN}[ ok ]${MOPS_RESET} $*"; }
mops_warn()  { echo -e "${MOPS_YELLOW}[warn]${MOPS_RESET} $*" >&2; }
mops_error() { echo -e "${MOPS_RED}[fail]${MOPS_RESET} $*" >&2; }
mops_die()   { mops_error "$*"; exit 1; }

mops_spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while ps -p $pid > /dev/null; do
    local temp=${spinstr#?}
    printf " [%c]  " "${spinstr%"${temp}"}"
    printf "\b\b\b\b\b\b"
    sleep $delay
    spinstr=$temp${spinstr%"${temp}"}
  done
  printf "    \b\b\b\b"
}

mops_json_log() {
  local level="$1"
  local event="$2"
  local message="$3"
  local project="${4:-global}"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Ensure log directory exists
  if [[ ! -d "/var/log/masterops" ]]; then
    sudo mkdir -p /var/log/masterops
    sudo chmod 777 /var/log/masterops
  fi

  # Structured JSON line for Loki/Grafana
  local json_line
  json_line=$(printf '{"timestamp":"%s","level":"%s","project":"%s","event":"%s","message":"%s"}' \
    "$timestamp" "$level" "$project" "$event" "$message")

  echo "$json_line" | sudo tee -a /var/log/masterops/masterops.log > /dev/null
}


MOPS_HOME="${MASTEROPS_HOME:-/usr/share/masterops}"
MOPS_PROJECTS_DIR="${MASTEROPS_PROJECTS_DIR:-$PWD}"

mops_ensure_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    mops_log "exists, skipping: $dir"
  else
    mkdir -p "$dir"
    mops_ok "created: $dir"
  fi
}

mops_ensure_file_from_template() {
  local template="$1" dest="$2"
  if [[ -f "$dest" ]]; then
    mops_warn "already exists, not overwriting: $dest"
    return 0
  fi
  [[ -f "$template" ]] || mops_die "template not found: $template"
  cp "$template" "$dest"
  mops_ok "wrote: $dest"
}

mops_command_exists() { command -v "$1" >/dev/null 2>&1; }


mops_confirm() {
  local prompt="$1"
  if [[ "${MOPS_ASSUME_YES:-0}" == "1" ]]; then
    return 0
  fi
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

mops_render_help() {
  local cmd="$1"
  local purpose="$2"
  local syntax="$3"
  local examples="$4"

  echo -e "\n${MOPS_BLUE}Command: ${MOPS_RESET}$cmd"
  echo -e "${MOPS_YELLOW}Purpose:  ${MOPS_RESET}$purpose"
  echo -e "${MOPS_YELLOW}Syntax:   ${MOPS_RESET}$syntax"
  echo -e "\n${MOPS_BLUE}Examples:${MOPS_RESET}"
  echo -e "$examples"
  echo -e "\n"
}


