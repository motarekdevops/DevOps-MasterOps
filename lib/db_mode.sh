#!/usr/bin/env bash

select_db_mode() {
    local db_name="$1"
    echo "How do you want to install '$db_name'?" >&2
    echo "  1) Container (Docker)" >&2
    echo "  2) Native (installed directly on server)" >&2
    read -rp "Choice [1]: " db_mode_choice
    case "$db_mode_choice" in
        2) echo "native" ;;
        *) echo "container" ;;
    esac
}

parse_preset() {
    local preset="$1"
    STACK_PATH="${preset%%:*}"
    STACK_MODE="${preset##*:}"
    if [[ "$STACK_PATH" == "$STACK_MODE" ]]; then
        STACK_MODE="container"
    fi
}

apply_stack() {
    local stack_path="$1"
    local stack_mode="$2"
    local project_dir="$3"

    if [[ "$stack_mode" == "container" ]]; then
        cp "$MASTEROPS_HOME/stacks/$stack_path/compose.fragment.yml" "$project_dir/"
        cp "$MASTEROPS_HOME/stacks/$stack_path/.env.example" "$project_dir/.env.example"
        echo "[masterops] $stack_path added as container."
    else
        echo "[masterops] Installing $stack_path natively on this server..."
        bash "$MASTEROPS_HOME/stacks/$stack_path/install-native.sh"
    fi
}

# Example integration call (run this where new.sh currently does the
# database stack selection, replacing the old single-mode copy logic):
#
#   DB_MODE=$(select_db_mode "postgres")
#   PRESET="database/postgres:${DB_MODE}"
#   parse_preset "$PRESET"
#   apply_stack "$STACK_PATH" "$STACK_MODE" "$PROJECT_DIR"
