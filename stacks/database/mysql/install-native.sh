#!/usr/bin/env bash
# Native install for MySQL on the host server (no container).
set -e

ENV_FILE="$1"

echo "[masterops] Installing MySQL natively..."
sudo apt update
sudo apt install -y mysql-server

sudo systemctl enable --now mysql

DB_NAME="changeme"
DB_USER="changeme"
DB_PASS="changeme"

if [[ -n "$ENV_FILE" ]] && [[ -f "$ENV_FILE" ]]; then
    DB_NAME=$(grep -E '^MYSQL_DATABASE=' "$ENV_FILE" | tail -n1 | cut -d= -f2-)
    DB_USER=$(grep -E '^MYSQL_USER=' "$ENV_FILE" | tail -n1 | cut -d= -f2-)
    DB_PASS=$(grep -E '^MYSQL_PASSWORD=' "$ENV_FILE" | tail -n1 | cut -d= -f2-)
fi

if [[ -z "$DB_NAME" || "$DB_NAME" == "changeme" ]]; then
    echo "[masterops] WARNING: MYSQL_DATABASE not set (or still 'changeme') in $ENV_FILE"
    echo "[masterops] Skipping DB/user creation. Edit .env.example, then run:"
    echo "[masterops]   sudo mysql -e \"CREATE DATABASE <db>;\""
    echo "[masterops]   sudo mysql -e \"CREATE USER '<user>'@'localhost' IDENTIFIED BY '<pass>';\""
    echo "[masterops]   sudo mysql -e \"GRANT ALL PRIVILEGES ON <db>.* TO '<user>'@'localhost';\""
    exit 0
fi

echo "[masterops] Creating database '$DB_NAME' and user '$DB_USER'..."

sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "[masterops] MySQL native install complete."
echo "[masterops] DB: $DB_NAME | User: $DB_USER | Port: 3306 | Host: 127.0.0.1"
