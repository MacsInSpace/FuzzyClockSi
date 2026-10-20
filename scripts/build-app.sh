#!/bin/zsh
# Builds a universal (arm64 + x86_64) Fuzzy Clock Si.app into ./build and signs it.
# Ad-hoc by default; SIGN_ID="Developer ID Application: …" signs with hardened runtime for notarization.
set -euo pipefail
cd "${0:A:h}/.."

APP="build/Fuzzy Clock Si.app"
swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/FuzzyClockSi"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/FuzzyClockSi"
cp -R Resources/Languages "$APP/Contents/Resources/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>FuzzyClockSi</string>
    <key>CFBundleIdentifier</key><string>local.fuzzyclocksi</string>
    <key>CFBundleName</key><string>Fuzzy Clock Si</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.2.0</string>
    <key>CFBundleVersion</key><string>2</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

SIGN_ID="${SIGN_ID:--}"
if [[ "$SIGN_ID" == "-" ]]; then
  codesign --force --sign - "$APP"
else
  codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$APP"
  codesign --verify --strict --verbose=2 "$APP"
fi
lipo -info "$APP/Contents/MacOS/FuzzyClockSi"
du -sh "$APP"
echo "Built: $APP"
