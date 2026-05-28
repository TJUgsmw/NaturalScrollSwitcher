#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="NaturalScrollSwitcher"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Packaging/Info.plist")"
ARCH="$(uname -m)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-macos-$ARCH.zip"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION-macos-$ARCH.dmg"
CHECKSUMS_PATH="$DIST_DIR/checksums.txt"

clear_problem_xattrs() {
    xattr -cr "$APP_DIR" 2>/dev/null || true
    xattr -d com.apple.FinderInfo "$APP_DIR" 2>/dev/null || true
}

"$ROOT_DIR/scripts/build_app.sh" >/dev/null

rm -f "$ZIP_PATH" "$DMG_PATH" "$CHECKSUMS_PATH"
clear_problem_xattrs

(
    cd "$DIST_DIR"
    ditto -c -k --keepParent "$APP_NAME.app" "$(basename "$ZIP_PATH")"
)

hdiutil create \
    -volname "$APP_NAME $VERSION" \
    -srcfolder "$APP_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

clear_problem_xattrs
shasum -a 256 "$ZIP_PATH" "$DMG_PATH" > "$CHECKSUMS_PATH"

echo "Created:"
echo "  $ZIP_PATH"
echo "  $DMG_PATH"
echo "  $CHECKSUMS_PATH"
