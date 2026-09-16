#!/usr/bin/env bash
# MasterOps V1 Verification Suite
set -euo pipefail

echo "🚀 Starting MasterOps V1 Verification..."

# 1. Version check
echo -n "Checking version... "
if [[ $("$MASTEROPS_HOME/bin/masterops" version) == *"v0.1.4"* ]]; then
  echo "✅"
else
  echo "❌"
  exit 1
fi

# 2. Help check
echo -n "Checking help... "
if "$MASTEROPS_HOME/bin/masterops" --help > /dev/null; then
  echo "✅"
else
  echo "❌"
  exit 1
fi

# 3. Command existence check
COMMANDS=("start" "status" "diff" "audit" "backup" "vault" "upgrade" "terraform" "nginx")
for cmd in "${COMMANDS[@]}"; do
  echo -n "Checking command '$cmd'... "
  if "$MASTEROPS_HOME/bin/masterops" "$cmd" --help > /dev/null 2>&1 || "$MASTEROPS_HOME/bin/masterops" "$cmd" > /dev/null 2>&1; then
    echo "✅"
  else
    echo "❌"
    exit 1
  fi
done

echo -e "\n🎉 All basic CLI checks passed!"
