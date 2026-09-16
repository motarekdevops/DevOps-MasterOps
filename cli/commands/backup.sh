#!/usr/bin/env bash
# MasterOps Manual Backup Command
# Triggers an immediate backup of all projects to S3.

set -euo pipefail
source "$MASTEROPS_HOME/cli/lib/common.sh"
source "$MASTEROPS_HOME/cli/lib/state.sh"

# Help handling
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  mops_render_help "backup" \
    "Trigger an immediate S3 backup of all projects and configuration." \
    "masterops backup" \
    "  masterops backup"
  exit 0
fi

mops_log "Triggering immediate S3 backup for all projects..."

if [[ ! -f "/opt/masterops/backups/backup.sh" ]]; then
  mops_error "Backup script not found. Please run 'masterops start' or ensure the s3_backups role is installed."
  mops_die "Backup infrastructure not initialized."
fi

sudo /opt/masterops/backups/backup.sh

if [[ $? -eq 0 ]]; then
  mops_ok "Backup process completed."
else
  mops_error "Backup process failed."
  mops_die "Backup failed."
fi
