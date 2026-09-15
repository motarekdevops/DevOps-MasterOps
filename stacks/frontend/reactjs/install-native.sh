#!/usr/bin/env bash
# Native install for a React frontend on the host server (no container).
# This only installs Node.js/npm and project dependencies -- it does NOT
# register a systemd service, since "npm run dev" is a foreground dev
# server, not a long-running daemon like Postgres or Nginx.
set -e

echo "[masterops] Installing Node.js and npm natively..."

if ! command -v node >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
fi

echo "[masterops] Node $(node -v) / npm $(npm -v) installed."
echo "[masterops] React native setup complete."
echo "[masterops] Next: cd frontend && npm install && npm run dev"
