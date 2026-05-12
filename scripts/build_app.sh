#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Countdown"
IDENTIFIER="com.example.countdown"
APP_VERSION="0.5.0"
BUNDLE_VERSION="5"
RELEASE_TAG="v0.5"

cd "$ROOT_DIR"

swift build -c release

BIN_PATH="$ROOT_DIR/.build/release/$APP_NAME"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "Missing built binary at: $BIN_PATH" >&2
  exit 1
fi

OUT_DIR="$ROOT_DIR/dist"
APP_DIR="$OUT_DIR/$APP_NAME.app"
ZIP_PATH="$OUT_DIR/$APP_NAME-$RELEASE_TAG-macOS.zip"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
rm -f "$ZIP_PATH"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

ICON_ICNS="$ROOT_DIR/Resources/AppIcon.icns"
if [[ ! -f "$ICON_ICNS" ]]; then
  echo "Generating app icon..."
  TMP_DIR="$(mktemp -d)"
  ICON_1024="$TMP_DIR/AppIcon-1024.png"
  ICONSET_DIR="$TMP_DIR/AppIcon.iconset"

  swift "$ROOT_DIR/scripts/generate_icon.swift" "$ICON_1024"

  mkdir -p "$ICONSET_DIR"
  sips -z 16 16 "$ICON_1024" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$ICON_1024" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$ICON_1024" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$ICON_1024" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$ICON_1024" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$ICON_1024" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$ICON_1024" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$ICON_1024" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$ICON_1024" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  cp "$ICON_1024" "$ICONSET_DIR/icon_512x512@2x.png"

  mkdir -p "$ROOT_DIR/Resources"
  iconutil -c icns "$ICONSET_DIR" -o "$ICON_ICNS"
  rm -rf "$TMP_DIR"
fi

cp "$ICON_ICNS" "$RESOURCES_DIR/AppIcon.icns"

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$IDENTIFIER</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUNDLE_VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent "$APP_DIR" "$ZIP_PATH"

echo "Built: $APP_DIR"
echo "Built archive: $ZIP_PATH"
echo "Tip: for coworker distribution, you may want to codesign+notarize."
