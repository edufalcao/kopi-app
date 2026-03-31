#!/bin/bash
set -euo pipefail

# Build Kopi.app and package it as a DMG for distribution.
# Usage: ./scripts/build-dmg.sh [version]
# Example: ./scripts/build-dmg.sh v1.0.0

VERSION="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"

echo "==> Building Kopi (Release)..."
xcodebuild \
  -project "$PROJECT_DIR/Kopi/Kopi.xcodeproj" \
  -scheme Kopi \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  build

APP_PATH="$DERIVED_DATA/Build/Products/Release/Kopi.app"

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: Kopi.app not found at $APP_PATH"
  exit 1
fi

echo "==> Creating DMG..."
DMG_NAME="Kopi-${VERSION}.dmg"

# Remove existing DMG if present
rm -f "$BUILD_DIR/$DMG_NAME"

create-dmg \
  --volname "Kopi" \
  --window-size 600 400 \
  --icon "Kopi.app" 150 190 \
  --app-drop-link 450 190 \
  "$BUILD_DIR/$DMG_NAME" \
  "$APP_PATH"

echo "==> Done: $BUILD_DIR/$DMG_NAME"
