#!/usr/bin/env bash
# MasterOps Security Audit Command
# Analyzes the server and individual projects for common security vulnerabilities.

set -euo pipefail
source "$MASTEROPS_HOME/cli/lib/common.sh"
source "$MASTEROPS_HOME/cli/lib/state.sh"

# Help handling
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  mops_render_help "audit" \
    "Run a comprehensive security audit of the server and deployed projects." \
    "masterops audit" \
    "  masterops audit"
  exit 0
fi

mops_log "Starting security audit..."

# 1. Server-Wide Audit (Existing Ansible Logic)
if ! mops_command_exists "ansible-playbook"; then
  mops_log "Ansible not found. Installing..."
  sudo apt-get update && sudo apt-get install -y ansible
fi

AUDIT_LOG="/tmp/masterops_audit.log"
mops_log "Running server-wide checks via Ansible..."
ansible-playbook "$MASTEROPS_HOME/ansible/playbooks/security_audit.yml" \
  -i "$MASTEROPS_HOME/ansible/inventory.ini" \
  > "$AUDIT_LOG" 2>&1 || true

echo -e "\n${MOPS_BLUE}--- Server Audit Results ---${MOPS_RESET}"
grep -E "WARNING|Open Port" "$AUDIT_LOG" || echo "No critical server-wide issues found."
echo -e "${MOPS_BLUE}----------------------------${MOPS_RESET}"

# 2. Project-Level Audit
echo -e "\n${MOPS_BLUE}--- Project Security Audit ---${MOPS_RESET}"

PROJECT_STATES=$(find /var/www -name "state.yaml" | grep ".masterops/state.yaml" || true)

if [[ -z "$PROJECT_STATES" ]]; then
  echo "No projects found to audit."
else
  for state_file in $PROJECT_STATES; do
    project_dir="$(dirname "$(dirname "$state_file")")"
    project_name="$(basename "$project_dir")"

    echo -e "\nChecking project: $project_name"

    # A. Ownership & Permissions
    owner=$(stat -c '%U' "$project_dir")
    perms=$(stat -c '%a' "$project_dir")
    if [[ "$owner" == "root" ]]; then
      mops_warn "  [!] Project directory owned by root (unsafe)"
    else
      mops_ok "  Ownership: $owner"
    fi
    if [[ "$perms" -gt 755 ]]; then
      mops_warn "  [!] Permissions too open: $perms"
    else
      mops_ok "  Permissions: $perms"
    fi

    # B. Exposed .env files
    if [[ -f "$project_dir/.env" ]]; then
      env_perms=$(stat -c '%a' "$project_dir/.env")
      if [[ "$env_perms" -gt 600 ]]; then
        mops_warn "  [!] .env file is world-readable ($env_perms)"
      else
        mops_ok "  .env permissions: secure"
      fi
    fi

    # C. Runtime User Check
    # Check if the systemd service is running as root
    if systemctl is-active --quiet "$project_name" 2>/dev/null; then
      service_user=$(systemctl show -p User "$project_name" | cut -d= -f2)
      if [[ "$service_user" == "root" || -z "$service_user" ]]; then
        mops_warn "  [!] Application service running as root"
      else
        mops_ok "  Service User: $service_user"
      fi
    else
      mops_warn "  Service not running; skipping user check"
    fi
  done
fi

echo -e "\n${MOPS_BLUE}-----------------------------${MOPS_RESET}"
mops_ok "Security audit completed."
