#!/usr/bin/env bash
# Shared helpers — sourced by every command, never executed directly.
# Created By MoTarek@DevOpsEngineer

set -euo pipefail

readonly MOPS_BLUE='\033[0;34m'
readonly MOPS_GREEN='\033[0;32m'
readonly MOPS_YELLOW='\033[0;33m'
readonly MOPS_RED='\033[0;31m'
readonly MOPS_RESET='\033[0m'

mops_log()   { echo -e "${MOPS_BLUE}[masterops]${MOPS_RESET} $*"; }
mops_ok()    { echo -e "${MOPS_GREEN}[ ok ]${MOPS_RESET} $*"; }
mops_warn()  { echo -e "${MOPS_YELLOW}[warn]${MOPS_RESET} $*" >&2; }
mops_error() { echo -e "${MOPS_RED}[fail]${MOPS_RESET} $*" >&2; }
mops_die()   { mops_error "$*"; exit 1; }


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


