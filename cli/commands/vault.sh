#!/usr/bin/env bash
# MasterOps Vault Command
# Manages encrypted project secrets.

set -euo pipefail
source "$MASTEROPS_HOME/cli/lib/common.sh"
source "$MASTEROPS_HOME/cli/lib/state.sh"
source "$MASTEROPS_HOME/cli/lib/vault.sh"

# Help handling
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  mops_render_help "vault" \
    "Manage encrypted project secrets using AES-256." \
    "masterops vault <set|unlock> <project> [key=value]" \
    "  masterops vault set my-app API_KEY=12345\n  masterops vault unlock my-app"
  exit 0
fi

mops_vault_init

CMD="$1"; shift || true
PROJECT_NAME="$1"; shift || true

[[ -z "$PROJECT_NAME" ]] && mops_die "usage: masterops vault <set|unlock> <project> [key=value]"

PROJECT_DIR="/var/www/$PROJECT_NAME"
[[ ! -d "$PROJECT_DIR" ]] && mops_die "Project $PROJECT_NAME not found at $PROJECT_DIR"

case "$CMD" in
  set)
    KEY_VAL="$1"
    [[ -z "$KEY_VAL" ]] && mops_die "usage: masterops vault set <project> <key=value>"
    mops_vault_set "$PROJECT_DIR" "$KEY_VAL"
    mops_ok "Secret set for $PROJECT_NAME"
    ;;
  unlock)
    mops_vault_decrypt "$PROJECT_DIR"
    mops_ok "Vault unlocked for $PROJECT_NAME"
    ;;
  *)
    mops_error "unknown vault action: $CMD"
    echo "Usage: masterops vault <set|unlock> <project> [key=value]"
    exit 1
    ;;
esac
