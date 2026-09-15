#!/usr/bin/env bash
# Generic interactive selection helpers, shared across all layers
# (backend, frontend, webserver, database).

# select_option <prompt> <opt1> <opt2> ...
# Prints the numbered menu to stderr, reads a number, echoes the
# selected option text to stdout (so it can be captured with $()).
select_option() {
    local prompt="$1"
    shift
    local options=("$@")

    echo "$prompt" >&2
    local i=1
    for opt in "${options[@]}"; do
        echo "  $i) $opt" >&2
        ((i++))
    done

    local choice
    read -rp "Choice [1]: " choice
    choice="${choice:-1}"

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
        echo "${options[$((choice-1))]}"
    else
        echo "${options[0]}"
    fi
}

# select_install_mode <layer_label>
# Returns one of: container | native | skip
select_install_mode() {
    local layer_label="$1"
    local choice
    choice=$(select_option \
        "How do you want to install '$layer_label'?" \
        "Docker Container" \
        "Native (installed directly on server)" \
        "Choose later (skip for now)")

    case "$choice" in
        "Docker Container") echo "container" ;;
        "Native"*)          echo "native" ;;
        *)                  echo "skip" ;;
    esac
}
