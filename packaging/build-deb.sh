#!/usr/bin/env bash
# Builds the MasterOps .deb package from the repo root using fpm.
# Usage: bash packaging/build-deb.sh
set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

VERSION=$(grep -oP 'readonly MOPS_VERSION="\K[^"]+' bin/masterops)
[[ -z "$VERSION" ]] && { echo "could not read version from bin/masterops"; exit 1; }

echo "[build-deb] building masterops v${VERSION}..."

fpm -s dir -t deb \
    -n masterops \
    -v "$VERSION" \
    --after-install packaging/debian/postinstall.sh \
    --prefix /usr/share/masterops \
    -C . \
    --exclude "*.git*" \
    --exclude "*.deb" \
    --exclude "testproject" \
    --exclude "packaging" \
    --exclude "README.md" \
    bin cli lib presets stacks

echo "[build-deb] done: masterops_${VERSION}_amd64.deb"
