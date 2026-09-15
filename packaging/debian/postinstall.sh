#!/usr/bin/env bash
set -e

chmod +x /usr/share/masterops/bin/masterops

# Ensure the CLI is on PATH via a symlink into /usr/local/bin, since
# fresh installs won't have it pre-created (only manual test setups did).
ln -sf /usr/share/masterops/bin/masterops /usr/local/bin/masterops
chmod +x /usr/local/bin/masterops

echo "MasterOps installed. Run: masterops doctor"
