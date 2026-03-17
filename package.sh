#!/bin/bash

# Configuration
APP_NAME="KeepAlive"
BUNDLE_NAME="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_NAME}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🚀 Building KeepAlive..."

# 1. Build the binary
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# 2. Create bundle structure
echo "📦 Creating app bundle..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 3. Copy binary
cp ".build/release/${APP_NAME}" "${MACOS_DIR}/"

# 4. Copy Info.plist
cp "Info.plist" "${CONTENTS_DIR}/"

echo "✅ Successfully created ${BUNDLE_NAME}!"
echo "👉 You can now move ${BUNDLE_NAME} to your Applications folder or open it directly."
