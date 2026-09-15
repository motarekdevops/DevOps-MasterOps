#!/usr/bin/env bash
source "$MASTEROPS_HOME/cli/lib/common.sh"

FAILS=0
WARNS=0

check_pass() { mops_ok "$1"; }
check_warn() { mops_warn "$1"; WARNS=$((WARNS+1)); }
check_fail() { mops_error "$1"; FAILS=$((FAILS+1)); }

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  case "$ID" in
    ubuntu|debian)
      check_pass "OS: $PRETTY_NAME (supported)"
      ;;
    *)
      if [[ "${ID_LIKE:-}" == *ubuntu* || "${ID_LIKE:-}" == *debian* ]]; then
        check_pass "OS: $PRETTY_NAME (Debian/Ubuntu-based, supported)"
      else
        check_warn "OS: $PRETTY_NAME — untested by MasterOps"
      fi
      ;;
  esac
else
  check_fail "Cannot detect OS (/etc/os-release missing)"
fi

total_ram_mb=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
if   [[ "$total_ram_mb" -ge 2048 ]]; then check_pass "RAM: ${total_ram_mb}MB (OK)"
elif [[ "$total_ram_mb" -ge 1024 ]]; then check_warn "RAM: ${total_ram_mb}MB (tight)"
else check_fail "RAM: ${total_ram_mb}MB (below 1GB)"
fi

avail_gb=$(df -BG --output=avail / | tail -1 | tr -dc '0-9')
if   [[ "$avail_gb" -ge 20 ]]; then check_pass "Disk free on /: ${avail_gb}G (OK)"
elif [[ "$avail_gb" -ge 10 ]]; then check_warn "Disk free on /: ${avail_gb}G (low)"
else check_fail "Disk free on /: ${avail_gb}G (too low)"
fi

if mops_command_exists docker; then
  check_pass "Docker installed: $(docker --version)"
  if ! docker info >/dev/null 2>&1; then
    check_warn "Docker daemon not reachable (need sudo or docker group)"
  fi
else
  check_warn "Docker not installed"
fi

echo "-----------------------------------"
echo "Result: $FAILS failing, $WARNS warnings"
if [[ "$FAILS" -gt 0 ]]; then
  mops_error "Server NOT ready."
  exit 1
elif [[ "$WARNS" -gt 0 ]]; then
  mops_warn "Usable, but review warnings."
  exit 0
else
  mops_ok "Server is ready."
  exit 0
fi


