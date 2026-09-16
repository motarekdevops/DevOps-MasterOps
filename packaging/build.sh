#!/usr/bin/env bash
set -e

VERSION="0.1.5"
PACKAGE_NAME="masterops"
BUILD_DIR="build_deb"
PKG_DIR="$BUILD_DIR/$PACKAGE_NAME"

echo "Building .deb package v$VERSION..."

# 1. Clean old build
rm -rf "$BUILD_DIR"

# 2. Create directory structure
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/masterops"

# 3. Copy project files to /usr/share/masterops
# We copy the core components of the framework
cp -r bin cli lib ansible templates "$PKG_DIR/usr/share/masterops/"

# 4. Create the symlink for the CLI
# This allows users to just type 'masterops' in their terminal
ln -s /usr/share/masterops/bin/masterops "$PKG_DIR/usr/bin/masterops"

# 5. Create the DEBIAN/control file
cat <<EOF > "$PKG_DIR/DEBIAN/control"
Package: $PACKAGE_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Mo Tarek <devops@masterops.io>
Description: MasterOps - The Professional DevOps Bootstrap Framework
 A comprehensive CLI for provisioning infrastructure and scaffolding
 full-stack projects with integrated CI/CD and state management.
EOF

# 6. Build the package
dpkg-deb --build "$PKG_DIR" "${PACKAGE_NAME}_${VERSION}_amd64.deb"

echo "--------------------------------------------------"
echo "SUCCESS: ${PACKAGE_NAME}_${VERSION}_amd64.deb created."
echo "To install: sudo dpkg -i ${PACKAGE_NAME}_${VERSION}_amd64.deb"
echo "--------------------------------------------------"

# Clean up
rm -rf "$BUILD_DIR"
