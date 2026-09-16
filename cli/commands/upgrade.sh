#!/usr/bin/env bash
# MasterOps Upgrade Utility
# Handles migrations of project state and configuration.

set -euo pipefail
source "$MASTEROPS_HOME/cli/lib/common.sh"
source "$MASTEROPS_HOME/cli/lib/state.sh"

# Help handling
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  mops_render_help "upgrade" \
    "Upgrade project configuration version and apply migrations." \
    "masterops upgrade <project_name>" \
    "  masterops upgrade my-app"
  exit 0
fi

PROJECT_NAME="${1:-}"
[[ -z "$PROJECT_NAME" ]] && mops_die "usage: masterops upgrade <project_name>"

PROJECT_DIR="/var/www/$PROJECT_NAME"
[[ ! -d "$PROJECT_DIR" ]] && mops_die "Project '$PROJECT_NAME' not found at $PROJECT_DIR"

TARGET_VERSION="1.0"
CURRENT_VERSION=$(mops_get_project_version "$PROJECT_DIR")

mops_log "Checking for updates for project: $PROJECT_NAME"
mops_log "Current version: ${CURRENT_VERSION:-none}"
mops_log "Target version: $TARGET_VERSION"

if [[ "$CURRENT_VERSION" == "$TARGET_VERSION" ]]; then
  mops_ok "Project is already up to date."
  exit 0
fi

mops_log "Upgrading project from ${CURRENT_VERSION:-none} to $TARGET_VERSION..."

# 1. Backup existing state
BACKUP_FILE="$PROJECT_DIR/.masterops/state.yaml.bak.$(date +%s)"
sudo cp "$PROJECT_DIR/.masterops/state.yaml" "$BACKUP_FILE"
mops_log "Backup created at $BACKUP_FILE"

# 2. Migration Logic
if [[ -z "$CURRENT_VERSION" ]]; then
  mops_log "Applying migration: Adding version field..."
  mops_set_project_state "$PROJECT_DIR" "version" "$TARGET_VERSION"
fi

# 3. Finalize
mops_set_project_state "$PROJECT_DIR" "status" "upgraded"
mops_ok "Project $PROJECT_NAME successfully upgraded to $TARGET_VERSION"
mops_json_log "info" "project_upgrade" "Upgraded project to $TARGET_VERSION" "$PROJECT_NAME"
