#!/usr/bin/env bash
set -euo pipefail

echo "=== Building Pipsey Native macOS Application Bundle ==="

# 1. Compile release binary
swift build -c release --product Pipsey

BIN_PATH=".build/release/Pipsey"
APP_DIR="build/Pipsey.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# 2. Copy binary
cp "${BIN_PATH}" "${MACOS_DIR}/Pipsey"
chmod +x "${MACOS_DIR}/Pipsey"

# 3. Create Info.plist
cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Pipsey</string>
    <key>CFBundleIdentifier</key>
    <string>com.pipsey.companion</string>
    <key>CFBundleName</key>
    <string>Pipsey</string>
    <key>CFBundleDisplayName</key>
    <string>Pipsey</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSScreenCaptureUsageDescription</key>
    <string>Pipsey needs Screen Recording permission to observe UI interactions that you demonstrate.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Pipsey needs Microphone permission to hear your questions aloud when you activate it.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Pipsey uses Speech Recognition to transcribe your verbal questions locally.</string>
</dict>
</plist>
EOF

# 4. Create PkgInfo
echo -n "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# 5. Copy brand icon and mascot assets
if [[ -f "Assets/AppIcon.icns" ]]; then
    cp Assets/AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
fi
if [[ -d "Assets" ]]; then
    cp Assets/*.png "${RESOURCES_DIR}/" || true
fi
if [[ -f "Assets/pipsey-logo.webp" ]]; then
    cp Assets/pipsey-logo.webp "${RESOURCES_DIR}/pipsey-logo.webp"
elif [[ -f "pipsey-logo.webp" ]]; then
    cp pipsey-logo.webp "${RESOURCES_DIR}/pipsey-logo.webp"
fi

# 6. Ad-hoc codesign bundle with TCC audio/screen entitlements
echo "Signing application bundle with entitlements..."
codesign --force --deep --sign - --entitlements entitlements.plist "${APP_DIR}"

echo "✅ Successfully built and signed ${APP_DIR}!"
echo "To launch: open ${APP_DIR}"
