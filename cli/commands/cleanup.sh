#!/usr/bin/env bash
# MasterOps Cleanup Utility
# Removes partially installed projects to allow for a clean retry.

source "$MASTEROPS_HOME/cli/lib/common.sh"
source "$MASTEROPS_HOME/cli/lib/state.sh"

PROJECT_NAME="${1:-}"
[[ -z "$PROJECT_NAME" ]] && mops_die "usage: masterops cleanup <project_name>"

PROJECT_DIR="/var/www/$PROJECT_NAME"

if [[ ! -d "$PROJECT_DIR" ]]; then
  mops_die "Project '$PROJECT_NAME' not found at $PROJECT_DIR"
fi

mops_log "--- MasterOps Cleanup ---"
mops_log "Target: $PROJECT_NAME"

if ! mops_confirm "Are you ABSOLUTELY sure you want to delete all files and state for '$PROJECT_NAME'? This cannot be undone."; then
  mops_die "cancelled."
fi

# 1. Remove files
mops_log "Removing project files..."
sudo rm -rf "$PROJECT_DIR"
mops_ok "files deleted."

# 2. Clean up global state
# We'll use yq to remove the project from the global list
sudo yq -i ".projects |= map(. != \"$PROJECT_NAME\")" "/etc/masterops/state.yaml"
mops_ok "global state updated."

mops_ok "\nProject '$PROJECT_NAME' has been completely wiped. You can now run 'masterops start $PROJECT_NAME' for a fresh install."
