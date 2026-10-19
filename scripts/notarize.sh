#!/bin/zsh
# Notarizes + staples build/Fuzzy Clock Si.app and writes build/FuzzyClockSi-<version>.zip.
#   SIGN_ID="Developer ID Application: …" ./scripts/build-app.sh
#   NOTARY_PROFILE=<notarytool keychain profile> ./scripts/notarize.sh
#   or APPLE_ID / APPLE_PASSWORD (app-specific) / APPLE_TEAM_ID in the environment
set -euo pipefail
cd "${0:A:h}/.."
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  AUTH=(--keychain-profile "$NOTARY_PROFILE")
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
  AUTH=(--apple-id "$APPLE_ID" --password "$APPLE_PASSWORD" --team-id "$APPLE_TEAM_ID")
else
  echo "Set NOTARY_PROFILE, or APPLE_ID + APPLE_PASSWORD + APPLE_TEAM_ID" >&2; exit 1
fi

APP="build/Fuzzy Clock Si.app"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
ZIP="build/FuzzyClockSi-$VERSION.zip"

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" "${AUTH[@]}" --wait
xcrun stapler staple "$APP"
spctl --assess --type execute --verbose "$APP"

# Re-zip so the download contains the stapled ticket.
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
shasum -a 256 "$ZIP"
