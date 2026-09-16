#!/usr/bin/env bash
# Builds the MasterOps .deb package from the repo root using fpm.
# Usage: bash packaging/build-deb.sh
set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

VERSION=$(grep -oP 'readonly MOPS_VERSION="\K[^"]+' bin/masterops)
[[ -z "$VERSION" ]] && { echo "could not read version from bin/masterops"; exit 1; }

echo "[build-deb] building masterops v${VERSION}..."

# We create a temporary staging area to ensure absolute paths in the .deb
STAGING_DIR=$(mktemp -d)
trap 'rm -rf "$STAGING_DIR"' EXIT

# 1. Binaries to /usr/bin
mkdir -p "$STAGING_DIR/usr/bin"
cp bin/masterops "$STAGING_DIR/usr/bin/masterops"
chmod +x "$STAGING_DIR/usr/bin/masterops"

# 2. Core assets to /usr/share/masterops
mkdir -p "$STAGING_DIR/usr/share/masterops"
cp -r cli lib presets stacks terraform ansible "$STAGING_DIR/usr/share/masterops/"
if [ -d "templates" ]; then
  cp -r templates "$STAGING_DIR/usr/share/masterops/"
fi

# 3. Man pages to /usr/share/man/man1
mkdir -p "$STAGING_DIR/usr/share/man/man1"
cp packaging/debian/man1/masterops.1 "$STAGING_DIR/usr/share/man/man1/"

# 4. Post-install script
mkdir -p "$STAGING_DIR/DEBIAN"
cp packaging/debian/postinstall.sh "$STAGING_DIR/DEBIAN/postinst"
chmod +x "$STAGING_DIR/DEBIAN/postinst"

# Use fpm to build the package from the staging directory
# First, remove the existing package to avoid fpm fatal error
echo "[build-deb] Cleaning old package..."
rm -f masterops_${VERSION}_amd64.deb

echo "[build-deb] Running fpm (this may take a few seconds)..."
fpm -s dir -t deb \
    -n masterops \
    -v "$VERSION" \
    --depends "python3-yaml" \
    --depends "python3" \
    --depends "curl" \
    --depends "openssl" \
    -C "$STAGING_DIR" .

echo "[build-deb] Package created successfully."


echo "[build-deb] done: masterops_${VERSION}_amd64.deb"
