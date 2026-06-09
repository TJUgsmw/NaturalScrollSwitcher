#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="NaturalScrollSwitcher"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
EXECUTABLE="$ROOT_DIR/.build/release/$APP_NAME"

clear_problem_xattrs() {
    xattr -cr "$APP_DIR" 2>/dev/null || true
    while IFS= read -r -d '' item; do
        xattr -d com.apple.FinderInfo "$item" 2>/dev/null || true
        xattr -d com.apple.ResourceFork "$item" 2>/dev/null || true
    done < <(find "$APP_DIR" -print0)
}

cd "$ROOT_DIR"
python3 "$ROOT_DIR/scripts/generate_assets.py" >/dev/null
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Packaging/Resources/"* "$APP_DIR/Contents/Resources/"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

clear_problem_xattrs
codesign --force --deep --sign - "$APP_DIR" >/dev/null
clear_problem_xattrs

echo "$APP_DIR"
