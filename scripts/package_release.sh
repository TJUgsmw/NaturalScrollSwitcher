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
RW_DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION-rw.dmg"
MOUNT_DIR="$DIST_DIR/dmg-mount"
VOLUME_NAME="$APP_NAME $VERSION"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/NaturalScrollSwitcherRelease.XXXXXX")"
STAGED_APP_DIR="$STAGING_DIR/$APP_NAME.app"

clear_problem_xattrs() {
    local target="${1:-$APP_DIR}"
    xattr -cr "$target" 2>/dev/null || true
    while IFS= read -r -d '' item; do
        xattr -d com.apple.FinderInfo "$item" 2>/dev/null || true
        xattr -d com.apple.ResourceFork "$item" 2>/dev/null || true
    done < <(find "$target" -print0)
}

verify_clean_signature() {
    local target="${1:-$APP_DIR}"
    local attempt
    for attempt in 1 2 3 4 5 6 7 8; do
        clear_problem_xattrs "$target"
        if codesign --verify --deep --strict "$target" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.5
    done

    clear_problem_xattrs "$target"
    codesign --verify --deep --strict "$target"
}

"$ROOT_DIR/scripts/build_app.sh" >/dev/null

rm -rf "$STAGED_APP_DIR"
ditto --norsrc "$APP_DIR" "$STAGED_APP_DIR"
verify_clean_signature "$STAGED_APP_DIR"

rm -f "$ZIP_PATH" "$DMG_PATH" "$CHECKSUMS_PATH" "$RW_DMG_PATH"
rm -rf "$MOUNT_DIR"

(
    cd "$STAGING_DIR"
    ditto -c -k --norsrc --keepParent "$APP_NAME.app" "$ZIP_PATH"
)

mkdir -p "$MOUNT_DIR"
hdiutil create \
    -size 40m \
    -fs HFS+ \
    -volname "$VOLUME_NAME" \
    -ov \
    "$RW_DMG_PATH" >/dev/null

hdiutil attach \
    -readwrite \
    -noverify \
    -noautoopen \
    -mountpoint "$MOUNT_DIR" \
    "$RW_DMG_PATH" >/dev/null

cleanup_mount() {
    hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
    rm -rf "$MOUNT_DIR"
    rm -rf "$STAGING_DIR"
}
trap cleanup_mount EXIT

ditto --norsrc "$STAGED_APP_DIR" "$MOUNT_DIR/$APP_NAME.app"
ln -s /Applications "$MOUNT_DIR/Applications"
mkdir -p "$MOUNT_DIR/.background"
cp "$ROOT_DIR/Packaging/Resources/DMGBackground.png" "$MOUNT_DIR/.background/DMGBackground.png"
xattr -cr "$MOUNT_DIR" 2>/dev/null || true

osascript >/dev/null 2>&1 <<APPLESCRIPT || true
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {120, 120, 840, 560}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 96
        set background picture of viewOptions to file ".background:DMGBackground.png"
        set position of item "$APP_NAME.app" of container window to {205, 275}
        set position of item "Applications" of container window to {515, 275}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

hdiutil detach "$MOUNT_DIR" -quiet
trap - EXIT
rm -rf "$MOUNT_DIR"

hdiutil convert \
    "$RW_DMG_PATH" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH" >/dev/null
rm -f "$RW_DMG_PATH"

sleep 1
verify_clean_signature "$STAGED_APP_DIR"

shasum -a 256 "$ZIP_PATH" "$DMG_PATH" > "$CHECKSUMS_PATH"
verify_clean_signature "$STAGED_APP_DIR"

rm -rf "$APP_DIR"
ditto --norsrc "$STAGED_APP_DIR" "$APP_DIR"
clear_problem_xattrs "$APP_DIR"
rm -rf "$STAGING_DIR"

echo "Created:"
echo "  $ZIP_PATH"
echo "  $DMG_PATH"
echo "  $CHECKSUMS_PATH"
