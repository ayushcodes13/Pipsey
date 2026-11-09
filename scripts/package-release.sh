#!/usr/bin/env bash
set -euo pipefail

echo "=== Packaging Pipsey Release Distribution DMG ==="

# 1. Ensure build-app.sh completes
./scripts/build-app.sh

APP_DIR="build/Pipsey.app"
if [[ ! -d "${APP_DIR}" ]]; then
    echo "Error: ${APP_DIR} not found!"
    exit 1
fi

VERSION="0.1.0"
DMG_NAME="Pipsey-${VERSION}.dmg"
DMG_PATH="build/${DMG_NAME}"
STAGING_DIR="build/dmg-staging"

rm -rf "${STAGING_DIR}" "${DMG_PATH}"
mkdir -p "${STAGING_DIR}"

# 2. Copy App into staging directory
cp -R "${APP_DIR}" "${STAGING_DIR}/"

# 3. Create Applications symlink for drag-and-drop installation
ln -s /Applications "${STAGING_DIR}/Applications"

# 4. Generate compressed UDZO DMG using native hdiutil
echo "Creating compressed disk image at ${DMG_PATH}..."
hdiutil create -volname "Pipsey" \
               -srcfolder "${STAGING_DIR}" \
               -ov \
               -format UDZO \
               "${DMG_PATH}"

rm -rf "${STAGING_DIR}"

echo "✅ Successfully generated distribution package: ${DMG_PATH}"
ls -lh "${DMG_PATH}"
