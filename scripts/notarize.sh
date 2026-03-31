#!/bin/bash
set -euo pipefail

# Notarize a Kopi DMG with Apple.
# Requires: APPLE_ID, TEAM_ID, APP_PASSWORD environment variables.
# Usage: ./scripts/notarize.sh path/to/Kopi-vX.Y.Z.dmg

DMG_PATH="${1:?Usage: notarize.sh <dmg-path>}"

if [ ! -f "$DMG_PATH" ]; then
  echo "ERROR: DMG not found at $DMG_PATH"
  exit 1
fi

echo "==> Submitting for notarization..."
xcrun notarytool submit "$DMG_PATH" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_PASSWORD" \
  --wait

echo "==> Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo "==> Done. DMG is notarized and stapled."
