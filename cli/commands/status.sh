#!/usr/bin/env bash
# MasterOps Status Utility
# Displays system-wide and project-specific health and configuration.

set -euo pipefail
source "$MASTEROPS_HOME/cli/lib/common.sh"
source "$MASTEROPS_HOME/cli/lib/state.sh"
source "$MASTEROPS_HOME/cli/lib/detect.sh"

# Help handling
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  mops_render_help "status" \
    "Show current system and project environment status." \
    "masterops status [project_name]" \
    "  masterops status                # Show all projects\n  masterops status <name>   # Show specific project"
  exit 0
fi

mops_init_global_state

# Handle single project request
if [[ -n "${1:-}" ]]; then
  TARGET_PROJECT="$1"
  PROJECT_DIR="/var/www/$TARGET_PROJECT"

  if [[ ! -d "$PROJECT_DIR" ]]; then
    mops_error "Project '$TARGET_PROJECT' not found at $PROJECT_DIR"
    exit 1
  fi

  # Display only the specific project
  echo -e "\n${MOPS_BLUE}Project: $TARGET_PROJECT${MOPS_RESET}"

  framework=$(detect_framework "$PROJECT_DIR/backend")
  runtime_ver="Unknown"

  case "$framework" in
    .NET)
      runtime_ver=$(dotnet --version 2>/dev/null || echo "Not Installed")
      ;;
    Django|Python)
      if [[ -d "$PROJECT_DIR/backend/venv" ]]; then
        runtime_ver="$($PROJECT_DIR/backend/venv/bin/python --version 2>&1)"
      else
        runtime_ver=$(python3 --version 2>&1 || echo "Not Installed")
      fi
      ;;
    Laravel|PHP)
      runtime_ver=$(php -v | head -n 1 | awk '{print $2}')
      ;;
    Go)
      runtime_ver=$(go version | awk '{print $3}')
      ;;
    *)
      runtime_ver="N/A"
      ;;
  esac

  echo "  Framework: $framework"
  echo "  Runtime:   $runtime_ver"

  dep_status="Ready"
  case "$framework" in
    .NET)
      [[ ! -d "$PROJECT_DIR/backend/obj" ]] && dep_status="Missing (run dotnet restore)"
      ;;
    Django|Python)
      [[ ! -d "$PROJECT_DIR/backend/venv" ]] && dep_status="Missing (venv not found)"
      ;;
    Laravel|PHP)
      [[ ! -d "$PROJECT_DIR/backend/vendor" ]] && dep_status="Missing (run composer install)"
      ;;
    Go)
      [[ ! -f "$PROJECT_DIR/backend/go.mod" ]] && dep_status="Missing (no go.mod)"
      ;;
  esac

  if [[ "$dep_status" == "Ready" ]]; then
    mops_ok "  Dependencies: Ready"
  else
    mops_warn "  Dependencies: $dep_status"
  fi

  if systemctl is-active --quiet "$TARGET_PROJECT" 2>/dev/null; then
    mops_ok "  Application: Running (Service: $TARGET_PROJECT)"
  else
    mops_error "  Application: Stopped"
  fi

  if [[ -L "/etc/nginx/sites-enabled/$TARGET_PROJECT" ]]; then
    mops_ok "  Nginx: Configured"
  else
    mops_warn "  Nginx: Not enabled"
  fi

  if (curl -s -f http://localhost || curl -s -f http://localhost:8080 || curl -s -f http://localhost:8000) > /dev/null 2>&1; then
    mops_ok "  Health: OK"
  else
    mops_warn "  Health: Unreachable"
  fi
  echo -e "\n"
  exit 0
fi

echo -e "\n${MOPS_BLUE}MasterOps System Status${MOPS_RESET}"

echo -e "────────────────────────────────────────"

echo -e "\n${MOPS_YELLOW}System${MOPS_RESET}"
echo -e "------"

# OS Detection
actual_os_distribution="$(. /etc/os-release && echo "$NAME")"
actual_os_version="$(. /etc/os-release && echo "$VERSION_ID")"
mops_ok "OS: $actual_os_distribution $actual_os_version"

# Docker Status
if command -v docker >/dev/null 2>&1; then
  actual_docker_version="$(docker --version)"
  mops_ok "Docker: $actual_docker_version"
else
  mops_warn "Docker: not installed"
fi

# Nginx Status
if command -v nginx >/dev/null 2>&1; then
  actual_nginx_version="$(nginx -v 2>&1)"
  mops_ok "Nginx: $actual_nginx_version"
  if systemctl is-active --quiet nginx; then
    mops_ok "Nginx service: active"
  else
    mops_error "Nginx service: inactive"
  fi
else
  mops_warn "Nginx: not installed"
fi

echo -e "\n${MOPS_YELLOW}Projects${MOPS_RESET}"
echo -e "--------"

# Find all projects by looking for .masterops/state.yaml
PROJECT_STATES=$(find /var/www -name "state.yaml" | grep ".masterops/state.yaml" || true)

if [[ -z "$PROJECT_STATES" ]]; then
  echo "No projects found under /var/www"
  exit 0
fi

for state_file in $PROJECT_STATES; do
  project_dir="$(dirname "$(dirname "$state_file")")"
  project_name="$(basename "$project_dir")"

  echo -e "\n${MOPS_BLUE}Project: $project_name${MOPS_RESET}"

  # 1. Framework & Runtime
  framework=$(detect_framework "$project_dir/backend")
  runtime_ver="Unknown"

  case "$framework" in
    .NET)
      runtime_ver=$(dotnet --version 2>/dev/null || echo "Not Installed")
      ;;
    Django|Python)
      if [[ -d "$project_dir/backend/venv" ]]; then
        runtime_ver="$($project_dir/backend/venv/bin/python --version 2>&1)"
      else
        runtime_ver=$(python3 --version 2>&1 || echo "Not Installed")
      fi
      ;;
    Laravel|PHP)
      runtime_ver=$(php -v | head -n 1 | awk '{print $2}')
      ;;
    Go)
      runtime_ver=$(go version | awk '{print $3}')
      ;;
    *)
      runtime_ver="N/A"
      ;;
  esac

  echo "  Framework: $framework"
  echo "  Runtime:   $runtime_ver"

  # 2. Dependencies Check
  dep_status="Ready"
  case "$framework" in
    .NET)
      [[ ! -d "$project_dir/backend/obj" ]] && dep_status="Missing (run dotnet restore)"
      ;;
    Django|Python)
      [[ ! -d "$project_dir/backend/venv" ]] && dep_status="Missing (venv not found)"
      ;;
    Laravel|PHP)
      [[ ! -d "$project_dir/backend/vendor" ]] && dep_status="Missing (run composer install)"
      ;;
    Go)
      [[ ! -f "$project_dir/backend/go.mod" ]] && dep_status="Missing (no go.mod)"
      ;;
  esac

  if [[ "$dep_status" == "Ready" ]]; then
    mops_ok "  Dependencies: Ready"
  else
    mops_warn "  Dependencies: $dep_status"
  fi

  # 3. Application & Service Status
  # Use the project name as the service name (our standard)
  if systemctl is-active --quiet "$project_name" 2>/dev/null; then
    mops_ok "  Application: Running (Service: $project_name)"
  else
    mops_error "  Application: Stopped"
  fi

  # 4. Nginx Config
  if [[ -L "/etc/nginx/sites-enabled/$project_name" ]]; then
    mops_ok "  Nginx: Configured"
  else
    mops_warn "  Nginx: Not enabled"
  fi

  # 5. Health Check
  # Attempt a simple curl to localhost - grouped to ensure all output is suppressed
  if (curl -s -f http://localhost || curl -s -f http://localhost:8080 || curl -s -f http://localhost:8000) > /dev/null 2>&1; then
    mops_ok "  Health: OK"
  else
    mops_warn "  Health: Unreachable"
  fi
done
echo -e "\n"
