#!/usr/bin/env bash
# MasterOps Drift Detection
# Compares desired state (masterops.yaml) with actual system state.

set -euo pipefail
source "$MASTEROPS_HOME/cli/lib/common.sh"
source "$MASTEROPS_HOME/cli/lib/state.sh"
source "$MASTEROPS_HOME/cli/lib/detect.sh"

# Help handling
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  mops_render_help "diff" \
    "Detect configuration and environment drift." \
    "masterops diff <project_name>" \
    "  masterops diff my-app"
  exit 0
fi

PROJECT_NAME="${1:-}"
if [[ -z "$PROJECT_NAME" ]]; then
  echo "Usage: masterops diff <project_name>"
  exit 2
fi

PROJECT_DIR="/var/www/$PROJECT_NAME"
[[ ! -d "$PROJECT_DIR" ]] && mops_die "Project '$PROJECT_NAME' not found at $PROJECT_DIR"

# 1. Load Desired State
CONFIG_FILE="$PROJECT_DIR/masterops.yaml"
[[ ! -f "$CONFIG_FILE" ]] && mops_die "Configuration file $CONFIG_FILE not found."

DESIRED_BACKEND=$(yq '.stacks[] | select(. == "backend/*")' "$CONFIG_FILE" | cut -d/ -f2)
DESIRED_DB=$(yq '.stacks[] | select(. == "database/*")' "$CONFIG_FILE" | cut -d/ -f2)
DESIRED_VERSION=$(yq '.version' "$CONFIG_FILE" | sed 's/"//g')

# 2. Detect Actual State
ACTUAL_BACKEND=$(detect_framework "$PROJECT_DIR/backend" | tr '[:upper:]' '[:lower:]')
ACTUAL_DB=$(detect_db_type "db_$PROJECT_NAME" "container")

COLOR_OK="${MOPS_GREEN}OK${MOPS_RESET}"
COLOR_DRIFT="${MOPS_RED}DRIFT${MOPS_RESET}"

DRIFT_DETECTED=0

echo -e "\n${MOPS_BLUE}MasterOps Drift Detection${MOPS_RESET}"
echo -e "──────────────────────────"
echo -e "Project: $PROJECT_DIR\n"

# --- Runtime/Framework Check ---
NORM_DESIRED_BACKEND=$(echo "$DESIRED_BACKEND" | tr '[:upper:]' '[:lower:]')
if [[ "$NORM_DESIRED_BACKEND" == "$ACTUAL_BACKEND" ]]; then
  STATUS="$COLOR_OK"
else
  STATUS="$COLOR_DRIFT"
  DRIFT_DETECTED=1
fi
echo -e "Framework\n  Expected: $DESIRED_BACKEND\n  Actual:   $ACTUAL_BACKEND\n  Status:   $STATUS\n"

# --- Database Check ---
NORM_DESIRED_DB=$(echo "$DESIRED_DB" | tr '[:upper:]' '[:lower:]')
if [[ "$NORM_DESIRED_DB" == "$ACTUAL_DB" ]] || [[ "$ACTUAL_DB" == "unknown"* ]]; then
  STATUS="$COLOR_OK"
else
  STATUS="$COLOR_DRIFT"
  DRIFT_DETECTED=1
fi
echo -e "Database\n  Expected: $DESIRED_DB\n  Actual:   $ACTUAL_DB\n  Status:   $STATUS\n"

# --- Version Check ---
if [[ "$DESIRED_VERSION" == "1.0" ]] || [[ -z "$DESIRED_VERSION" ]]; then
  STATUS="$COLOR_OK"
else
  STATUS="$COLOR_DRIFT"
  DRIFT_DETECTED=1
fi
echo -e "Config Version\n  Expected: ${DESIRED_VERSION:-1.0}\n  Actual:   1.0\n  Status:   $STATUS\n"

if [[ $DRIFT_DETECTED -eq 1 ]]; then
  mops_warn "Drift detected in project $PROJECT_NAME!"
  exit 1
else
  mops_ok "No drift detected. Project is in sync."
  exit 0
fi
