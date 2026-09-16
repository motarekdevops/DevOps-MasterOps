#!/usr/bin/env bash
# State management for MasterOps
# Uses yq for professional YAML handling

source "$MASTEROPS_HOME/cli/lib/common.sh"

GLOBAL_STATE_DIR="/etc/masterops"
GLOBAL_STATE_FILE="$GLOBAL_STATE_DIR/state.yaml"

mops_ensure_yq() {
  if ! command -v yq >/dev/null 2>&1; then
    mops_log "Installing yq for state management..."
    sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
    mops_ok "yq installed."
  fi
}

mops_init_global_state() {
  mops_ensure_yq
  if [[ ! -d "$GLOBAL_STATE_DIR" ]]; then
    sudo mkdir -p "$GLOBAL_STATE_DIR"
    sudo chmod 755 "$GLOBAL_STATE_DIR"
  fi

  if [[ ! -f "$GLOBAL_STATE_FILE" ]]; then
    echo "projects: []" | sudo tee "$GLOBAL_STATE_FILE" > /dev/null
    echo "installed_tools: []" | sudo tee -a "$GLOBAL_STATE_FILE" > /dev/null
    sudo chmod 666 "$GLOBAL_STATE_FILE"
  fi
}

mops_get_global_state() {
  local key="$1"
  # Use yq to get the value, then replace literal 'null' with an empty string
  yq ".${key}" "$GLOBAL_STATE_FILE" | sed 's/^null$//'
}

mops_add_global_tool() {
  local tool="$1"
  # Use -i -y for in-place YAML updates
  sudo yq -i -y ".installed_tools += [\"$tool\"] | .installed_tools |= unique" "$GLOBAL_STATE_FILE"
}

mops_init_project_state() {
  local project_dir="$1"
  local state_dir="$project_dir/.masterops"
  local state_file="$state_dir/state.yaml"

  mops_ensure_dir "$state_dir"
  if [[ ! -f "$state_file" ]]; then
    cat <<EOF > "$state_file"
version: "1.0"
project_name: $(basename "$project_dir")
created_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
status: initializing
EOF
    mops_ok "initialized project state at $state_file"
  fi
}

mops_get_project_version() {
  local project_dir="$1"
  mops_get_project_state "$project_dir" "version"
}

mops_validate_project_version() {
  local project_dir="$1"
  local current_version
  current_version=$(mops_get_project_version "$project_dir")

  if [[ -z "$current_version" ]]; then
    mops_warn "No version found in state. Defaulting to 1.0"
    echo "1.0"
  else
    echo "$current_version"
  fi
}


mops_set_project_state() {
  local project_dir="$1"
  local key="$2"
  local value="$3"
  local state_file="$project_dir/.masterops/state.yaml"

  # Use -i -y for in-place YAML updates
  sudo yq -i -y ".${key} = \"${value}\"" "$state_file"
}

mops_get_project_state() {
  local project_dir="$1"
  local key="$2"
  local state_file="$project_dir/.masterops/state.yaml"

  if [[ -f "$state_file" ]]; then
    yq ".${key}" "$state_file" | sed 's/^"//;s/"$//'
  fi
}
