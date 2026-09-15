#!/usr/bin/env bash
# Shared port-availability check, used by any web server's
# install-native.sh before enabling its systemd service.

# check_port_free <port> <service_label>
# Prints a warning to stderr and returns 1 if the port is already
# in use by something else. Returns 0 if the port is free.
check_port_free() {
    local port="$1"
    local service_label="$2"

    local holder
    holder=$(sudo ss -tlnp 2>/dev/null | awk -v p=":${port}\$" '$4 ~ p {print $0}')

    if [[ -n "$holder" ]]; then
        echo "[masterops] WARNING: port $port is already in use -- $service_label may fail to start." >&2
        echo "[masterops] Current listener on port $port:" >&2
        echo "$holder" >&2
        return 1
    fi

    return 0
}
