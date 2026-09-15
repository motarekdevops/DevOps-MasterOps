#!/usr/bin/env bash
set -e

ENV_FILE="$1"

echo "[masterops] Installing PostgreSQL natively..."
sudo apt update
sudo apt install -y postgresql postgresql-contrib

sudo systemctl enable --now postgresql

# Pull values written by new.sh's .env.example generation (from
# stacks/database/postgres/.env.example: POSTGRES_DB/USER/PASSWORD)
DB_NAME="changeme"
DB_USER="changeme"
DB_PASS="changeme"

if [[ -n "$ENV_FILE" ]] && [[ -f "$ENV_FILE" ]]; then
    DB_NAME=$(grep -E '^POSTGRES_DB=' "$ENV_FILE" | tail -n1 | cut -d= -f2-)
    DB_USER=$(grep -E '^POSTGRES_USER=' "$ENV_FILE" | tail -n1 | cut -d= -f2-)
    DB_PASS=$(grep -E '^POSTGRES_PASSWORD=' "$ENV_FILE" | tail -n1 | cut -d= -f2-)
fi

if [[ -z "$DB_NAME" || "$DB_NAME" == "changeme" ]]; then
    echo "[masterops] WARNING: POSTGRES_DB not set (or still 'changeme') in $ENV_FILE"
    echo "[masterops] Skipping DB/user creation. Edit .env.example, then run:"
    echo "[masterops]   sudo -u postgres psql -c \"CREATE DATABASE <db>;\""
    echo "[masterops]   sudo -u postgres psql -c \"CREATE USER <user> WITH PASSWORD '<pass>';\""
    echo "[masterops]   sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE <db> TO <user>;\""
    exit 0
fi

echo "[masterops] Creating database '$DB_NAME' and user '$DB_USER'..."

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1 \
    || sudo -u postgres psql -c "CREATE DATABASE \"${DB_NAME}\";"

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}'" | grep -q 1 \
    || sudo -u postgres psql -c "CREATE USER \"${DB_USER}\" WITH PASSWORD '${DB_PASS}';"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE \"${DB_NAME}\" TO \"${DB_USER}\";"

echo "[masterops] PostgreSQL native install complete."
echo "[masterops] DB: $DB_NAME | User: $DB_USER | Port: 5432 | Host: 127.0.0.1"
