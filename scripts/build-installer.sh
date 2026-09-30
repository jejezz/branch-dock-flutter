#!/usr/bin/env bash
# Build the macOS installer (DMG) locally, the same way
# .github/workflows/release.yml's `build-macos` job does.
#
# Reads the app metadata from the same sources as the workflow:
#   display name  macos/Runner/Configs/AppInfo.xcconfig  (PRODUCT_NAME)
#   file name     display name without non-alphanumerics
#   version       pubspec.yaml (the `+build` part is dropped)
# then runs `flutter build macos --release` and packages the .app into a DMG.
#
# Output: dist/<FileName>-<version>-macos-universal.dmg
#
# Usage:
#   scripts/build-installer.sh
#   scripts/build-installer.sh --skip-build
#   scripts/build-installer.sh --version 1.5.0-rc.1
#
# Optional environment (all unset = ad-hoc signed, Gatekeeper warns on first launch):
#   SIGN_IDENTITY   codesign identity, e.g. "Developer ID Application: Name (TEAMID)"
#   NOTARY_PROFILE  `xcrun notarytool store-credentials` profile; notarizes and
#                   staples the DMG (needs SIGN_IDENTITY)
set -euo pipefail

cd "$(dirname "$0")/.."

SKIP_BUILD=false
VERSION=""
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-build) SKIP_BUILD=true ;;
    --version) VERSION="${2:?--version needs a value}"; shift ;;
    -h|--help) sed -n '2,/^set -/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This script must run on macOS." >&2
  exit 1
fi
if [ -n "${NOTARY_PROFILE:-}" ] && [ -z "${SIGN_IDENTITY:-}" ]; then
  echo "NOTARY_PROFILE requires SIGN_IDENTITY (notarization needs a Developer ID signature)." >&2
  exit 1
fi

DISPLAY_NAME=$(grep '^PRODUCT_NAME' macos/Runner/Configs/AppInfo.xcconfig | head -1 \
  | sed -E 's/^PRODUCT_NAME[[:space:]]*=[[:space:]]*//' | tr -d '\r')
test -n "$DISPLAY_NAME"
FILE_NAME=$(printf '%s' "$DISPLAY_NAME" | tr -cd '[:alnum:]')
if [ -z "$VERSION" ]; then
  VERSION=$(grep '^version:' pubspec.yaml | head -1 \
    | sed -E 's/^version:[[:space:]]*([^+[:space:]]+).*/\1/')
fi
test -n "$VERSION"

DMG_NAME="${FILE_NAME}-${VERSION}-macos-universal.dmg"
echo "$DISPLAY_NAME $VERSION -> $DMG_NAME"

if [ "$SKIP_BUILD" = false ]; then
  flutter build macos --release
fi

RELEASE_DIR="build/macos/Build/Products/Release"
APP_NAME=$(ls "$RELEASE_DIR" 2>/dev/null | grep '\.app$' | head -1 || true)
if [ -z "$APP_NAME" ]; then
  echo "No .app in $RELEASE_DIR. Run without --skip-build." >&2
  exit 1
fi
APP_PATH="$RELEASE_DIR/$APP_NAME"

if [ -n "${SIGN_IDENTITY:-}" ]; then
  codesign --force --deep --options runtime --timestamp \
    --entitlements macos/Runner/Release.entitlements \
    --sign "$SIGN_IDENTITY" "$APP_PATH"
  codesign --verify --deep --strict --verbose=2 "$APP_PATH"
fi

mkdir -p dist
DMG_PATH="dist/$DMG_NAME"
rm -f "$DMG_PATH"

if command -v create-dmg >/dev/null 2>&1; then
  # create-dmg sometimes exits non-zero over unrelated warnings even after
  # producing a working DMG, so only check that the file exists.
  create-dmg \
    --volname "$DISPLAY_NAME" \
    --window-size 500 300 \
    --icon-size 100 \
    --app-drop-link 380 120 \
    "$DMG_PATH" \
    "$APP_PATH" || true
else
  echo "create-dmg not found (brew install create-dmg); using a plain hdiutil DMG." >&2
  STAGE=$(mktemp -d)
  trap 'rm -rf "$STAGE"' EXIT
  cp -R "$APP_PATH" "$STAGE/"
  ln -s /Applications "$STAGE/Applications"
  hdiutil create -volname "$DISPLAY_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG_PATH"
fi
test -f "$DMG_PATH"

if [ -n "${NOTARY_PROFILE:-}" ]; then
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
fi

echo "Done: $PWD/$DMG_PATH"
