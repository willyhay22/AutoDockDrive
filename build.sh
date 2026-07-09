#!/bin/bash
set -e

APP_NAME="AutoDockDrive"
BUNDLE_IDENTIFIER="com.wihay.AutoDockDrive"
VERSION="1.0"
SRC_DIR="Sources"
BUILD_DIR="build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MAC_OS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "Building ${APP_NAME}..."

# Clean build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${MAC_OS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Compile Swift files
swiftc -O \
    "${SRC_DIR}/AppDelegate.swift" \
    "${SRC_DIR}/DockManager.swift" \
    "${SRC_DIR}/Logger.swift" \
    "${SRC_DIR}/SettingsManager.swift" \
    "${SRC_DIR}/VolumeMonitor.swift" \
    "${SRC_DIR}/PreferencesWindowController.swift" \
    "${SRC_DIR}/AboutWindowController.swift" \
    "${SRC_DIR}/WelcomeWindowController.swift" \
    "${SRC_DIR}/main.swift" \
    -o "${MAC_OS_DIR}/${APP_NAME}" \
    -target x86_64-apple-macosx12.0 \
    -target arm64-apple-macosx12.0

# Create Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_IDENTIFIER}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSMultipleInstancesProhibited</key>
    <true/>
</dict>
</plist>
EOF

# Copy Icon
if [ -f "Assets/icon.icns" ]; then
    cp "Assets/icon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Code Sign the application bundle (ad-hoc signing for distribution if proper certs are missing)
echo "Signing ${APP_NAME}..."
codesign --force --deep --sign - "${APP_DIR}"

echo "Creating DMG..."
# Create a temporary directory for DMG contents
DMG_SRC_DIR="${BUILD_DIR}/dmg_src"
mkdir -p "${DMG_SRC_DIR}"
cp -R "${APP_DIR}" "${DMG_SRC_DIR}/"
ln -s /Applications "${DMG_SRC_DIR}/Applications"

# Generate DMG using hdiutil
hdiutil create -volname "${APP_NAME}" -srcfolder "${DMG_SRC_DIR}" -ov -format UDZO "${BUILD_DIR}/${DMG_NAME}"

echo "Done! DMG is located at: ${BUILD_DIR}/${DMG_NAME}"
