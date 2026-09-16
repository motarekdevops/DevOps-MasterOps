#!/usr/bin/env bash
# MasterOps Framework Wizard v2
# A robust orchestrator for project bootstrapping.

# We explicitly disable 'set -e' for the interactive part to prevent crashes
# during user input or non-critical utility failures.
set +e

source "$MASTEROPS_HOME/cli/lib/common.sh"
source "$MASTEROPS_HOME/cli/lib/state.sh"

PROJECT_NAME="${1:-}"
[[ -z "$PROJECT_NAME" ]] && mops_die "usage: masterops start <project_name>"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  mops_render_help "start" "Bootstrap a new framework project with full environment provisioning." "masterops start <project_name>" "  masterops start my-awesome-app"
  exit 0
fi
# 1. Initialization
mops_init_global_state
PROJECT_DIR="/var/www/$PROJECT_NAME"

validate_domain() {
  local domain="$1"
  [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

mops_json_log "info" "wizard_start" "Starting Framework Wizard v2 for $PROJECT_NAME" "$PROJECT_NAME"
mops_log "\n${MOPS_BLUE}======================================================${MOPS_RESET}"
mops_log "${MOPS_GREEN}   🚀 MasterOps Framework Wizard v2${MOPS_RESET}"
mops_log "${MOPS_BLUE}======================================================${MOPS_RESET}"
mops_log "Project: $PROJECT_NAME"

if [[ -d "$PROJECT_DIR" ]]; then
  mops_warn "Project '$PROJECT_NAME' already exists at $PROJECT_DIR"
  if ! mops_confirm "Would you like to resume/update this project?"; then
    mops_die "Operation cancelled by user."
  fi
  mops_json_log "info" "wizard_resume" "Resuming existing project" "$PROJECT_NAME"
else
  mops_log "Creating project directory at $PROJECT_DIR..."
  sudo mkdir -p "$PROJECT_DIR"
  sudo chown "$USER":"$USER" "$PROJECT_DIR"
  mops_init_project_state "$PROJECT_DIR"
  mops_json_log "info" "project_created" "Created new project directory" "$PROJECT_NAME"
fi

# 2. Configuration Wizard
mops_log "\n${MOPS_BLUE}--- Framework Configuration ---${MOPS_RESET}"

ask_by_list() {
  local key="$1"
  local prompt="$2"
  shift 2
  local options=("$@")

  # Retrieve current value from state using helper
  local current_val
  current_val=$(mops_get_project_state "$PROJECT_DIR" "$key")

  # Use stderr for prompts and options to avoid capturing them in variables
  echo -e "\n$prompt" >&2
  for i in "${!options[@]}"; do
    echo "$((i+1))) ${options[$i]}" >&2
  done

  local final_default="1"
  if [[ -n "$current_val" ]]; then
    for i in "${!options[@]}"; do
      if [[ "${options[$i]}" == "$current_val" ]]; then
        final_default=$((i+1))
        break
      fi
    done
  fi

  read -p "Select option [$final_default]: " choice
  choice="${choice:-$final_default}"

  if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#options[@]}" ]; then
    mops_warn "Invalid choice. Using default: ${options[0]}"
    choice=1
  fi

  local result="${options[$((choice-1))]}"
  mops_set_project_state "$PROJECT_DIR" "$key" "$result"
  echo -e "${MOPS_GREEN}  $\rightarrow$ $result set${MOPS_RESET}" >&2
  echo "$result"
}

# --- Backend ---
BACKEND_OPTIONS=("laravel" "dotnet" "springboot" "go" "django")
BACKEND_FW=$(ask_by_list "backend" "Select Backend Framework" "${BACKEND_OPTIONS[@]}")

# --- Frontend ---
FRONTEND_OPTIONS=("react" "vue" "nextjs" "svelte" "angular")
FRONTEND_FW=$(ask_by_list "frontend" "Select Frontend Framework" "${FRONTEND_OPTIONS[@]}")

# --- Database ---
DB_OPTIONS=("postgres" "mysql" "mariadb" "redis")
DB_TYPE=$(ask_by_list "database" "Select Database Engine" "${DB_OPTIONS[@]}")

# --- Mode ---
MODE_OPTIONS=("container" "native")
INSTALL_MODE=$(ask_by_list "mode" "Installation Mode" "${MODE_OPTIONS[@]}")

# --- Web Server ---
WS_OPTIONS=("nginx" "apache")
WEB_SERVER=$(ask_by_list "webserver" "Select Web Server" "${WS_OPTIONS[@]}")

# --- Domain ---
while true; do
  read -p "Enter Domain Name (e.g. example.com): " DOMAIN
  if validate_domain "$DOMAIN"; then
    mops_set_project_state "$PROJECT_DIR" "domain" "$DOMAIN"
    break
  fi
  mops_warn "Invalid domain format. Please try again."
done

# --- Orchestration ---
K8S_OPTIONS=("false" "true")
K8S_VAL=$(ask_by_list "k8s" "Do you need Kubernetes/Helm clusters?" "${K8S_OPTIONS[@]}")

mops_log "\n${MOPS_BLUE}--- Configuration Summary ---${MOPS_RESET}"
mops_log "Project:    $PROJECT_NAME"
mops_log "Backend:    $BACKEND_FW"
mops_log "Frontend:   $FRONTEND_FW"
mops_log "Database:   $DB_TYPE ($INSTALL_MODE)"
mops_log "Webserver:  $WEB_SERVER ($DOMAIN)"
mops_log "K8s:        $K8S_VAL"

if ! mops_confirm "Proceed with installation?"; then
  mops_json_log "warn" "wizard_cancelled" "User cancelled installation" "$PROJECT_NAME"
  mops_die "Installation cancelled."
fi

# 3. Execution Phase
mops_json_log "info" "install_start" "Beginning Ansible deployment" "$PROJECT_NAME"
mops_log "\nBuilding your framework... this may take a few minutes."

# Generate a random database password
DB_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9')
mops_set_project_state "$PROJECT_DIR" "db_password" "$DB_PASSWORD"

VARS_FILE="/tmp/masterops_vars_${PROJECT_NAME}.yml"
	sudo rm -f "$VARS_FILE"
	cat <<EOF > "$VARS_FILE"
project_name: "$PROJECT_NAME"
backend_fw: "$BACKEND_FW"
frontend_fw: "$FRONTEND_FW"
db_type: "$DB_TYPE"
install_mode: "$INSTALL_MODE"
webserver: "$WEB_SERVER"
domain: "$DOMAIN"
k8s: $K8S_VAL
project_path: "$PROJECT_DIR"
db_password: "$DB_PASSWORD"
EOF

if ! mops_command_exists "ansible-playbook"; then
  mops_log "Ansible not found. Installing..."
  sudo apt-get update && sudo apt-get install -y ansible
fi

# Run Ansible and stream output to both log and console
# We use a while loop to read the log in real-time and update a progress bar
LOG_FILE="/tmp/masterops_ansible_${PROJECT_NAME}.log"
ansible-playbook "$MASTEROPS_HOME/ansible/site.yml" -i "$MASTEROPS_HOME/ansible/inventory.ini" -e "@$VARS_FILE" > "$LOG_FILE" 2>&1 &
ANS_PID=$!


mops_log "Deploying components..."

# Total tasks estimate (approximate based on roles)
TOTAL_TASKS=40
CURRENT_TASK=0

while ps -p $ANS_PID > /dev/null; do
  # Count tasks completed so far by looking for 'ok:', 'changed:', 'fatal:', 'skipping:'
  CURRENT_TASK=$(grep -Ec "ok: |changed: |fatal: |skipping: " "$LOG_FILE" || echo 0)

  # Calculate percentage
  # Use a safe numeric evaluation to prevent bash syntax errors
  RAW_COUNT=$(grep -Ec "ok: |changed: |fatal: |skipping: " "$LOG_FILE" || echo 0)
  CURRENT_TASK_VAL=$(echo "$RAW_COUNT" | tr -dc '0-9')
  [[ -z "$CURRENT_TASK_VAL" ]] && CURRENT_TASK_VAL=0

  PERCENT=$(( CURRENT_TASK_VAL * 100 / TOTAL_TASKS ))
  [[ $PERCENT -gt 100 ]] && PERCENT=100

  # Create a visual progress bar
  BAR_SIZE=20
  FILLED=$(( PERCENT * BAR_SIZE / 100 ))
  EMPTY=$(( BAR_SIZE - FILLED ))
  BAR=$(printf "%${FILLED}s" | tr ' ' '#')
  SPACES=$(printf "%${EMPTY}s" | tr ' ' '-')

  # Print the progress bar on the same line
  printf "\r [%s%s] %d%% (%d/%d tasks)" "$BAR" "$SPACES" "$PERCENT" "$CURRENT_TASK_VAL" "$TOTAL_TASKS"

  sleep 0.5
done
echo -e "\n"

wait $ANS_PID
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
  echo -e "\n${MOPS_GREEN}======================================================${MOPS_RESET}"
  echo -e "${MOPS_GREEN}   🚀 PROJECT SUCCESSFULLY PROVISIONED!${MOPS_RESET}"
  echo -e "${MOPS_GREEN}======================================================${MOPS_RESET}"
  echo -e "${MOPS_BLUE}Project Name:${MOPS_RESET} $PROJECT_NAME"
  echo -e "${MOPS_BLUE}Base Path:   ${MOPS_RESET} $PROJECT_DIR"
  echo -e "${MOPS_BLUE}Public URL:  ${MOPS_RESET} http://$DOMAIN"
  echo -e "${MOPS_BLUE}Backend:     ${MOPS_RESET} $BACKEND_FW"
  echo -e "${MOPS_BLUE}Frontend:    ${MOPS_RESET} $FRONTEND_FW"
  echo -e "${MOPS_BLUE}Database:    ${MOPS_RESET} $DB_TYPE ($INSTALL_MODE)"
  echo -e "${MOPS_BLUE}CI/CD:       ${MOPS_RESET} GitHub Actions (Injected)"
  echo -e "${MOPS_GREEN}------------------------------------------------------${MOPS_RESET}"
  echo -e "${MOPS_YELLOW}Next Steps:${MOPS_RESET}"
  echo -e "  1. Push your code to GitHub"
  echo -e "  2. Configure secrets in GitHub (SERVER_HOST, SERVER_USER, SSH_PRIVATE_KEY)"
  echo -e "  3. Monitor logs at: /var/log/masterops/$PROJECT_NAME/"
  echo -e "${MOPS_GREEN}======================================================${MOPS_RESET}\n"

  mops_ok "\nProject '$PROJECT_NAME' is now ready!"
  mops_json_log "info" "install_success" "Framework successfully deployed" "$PROJECT_NAME"
else
  mops_error "\nDeployment failed. Detailed Error Log:"
  echo -e "${MOPS_RED}------------------------------------------------------${MOPS_RESET}"
  cat "$LOG_FILE"
  echo -e "${MOPS_RED}------------------------------------------------------${MOPS_RESET}"
  mops_json_log "error" "install_fail" "Ansible deployment failed" "$PROJECT_NAME"
  mops_die "Ansible deployment failed. Please check the logs above."
fi

mops_add_global_tool "$WEB_SERVER"
mops_add_global_tool "$DB_TYPE"
[[ "$INSTALL_MODE" == "container" ]] && mops_add_global_tool "docker"

mops_log "Log files available at: /var/log/masterops/$PROJECT_NAME/"
mops_log "State file updated at: $PROJECT_DIR/.masterops/state.yaml"
