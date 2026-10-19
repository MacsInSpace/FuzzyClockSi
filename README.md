# Fuzzy Clock Si

A clean-room, Apple Silicon–native (universal) replacement for **FuzzyTime** by Marcus Olovsson
(`com.mrcs.FuzzyTime` 1.2.3), which is x86_64-only and needs Rosetta 2.

Menu bar shows the time as words: "ten to eleven", "halb drei", "MON QUARTER PAST TWO".

## Build & run

```sh
swift test                      # engine tests
./scripts/build-app.sh          # -> build/Fuzzy Clock Si.app (arm64 + x86_64, ad-hoc signed)
open "build/Fuzzy Clock Si.app"
"build/Fuzzy Clock Si.app/Contents/MacOS/FuzzyClockSi" --print 14:25   # CLI check
```

No dependencies. macOS 13+.

### Signing & notarization

Release builds are signed with a Developer ID but **not notarized yet** (pending an Apple
agreement renewal). On first launch: right-click → Open, or
`xattr -dr com.apple.quarantine "/Applications/Fuzzy Clock Si.app"`.

To produce a notarized build:

```sh
SIGN_ID="Developer ID Application: …" ./scripts/build-app.sh
NOTARY_PROFILE=<profile> ./scripts/notarize.sh   # or APPLE_ID / APPLE_PASSWORD / APPLE_TEAM_ID
```

## Features

- Fuzzy time in the menu bar, updated on the minute boundary, wake, and clock/timezone changes
- Languages: English bundled; **Settings → Import languages from FuzzyTime.app** copies the
  original's 60+ language/dialect folders into
  `~/Library/Application Support/FuzzyClockSi/Languages` (for personal use: that data is the
  original author's work, so it is not committed here)
- Fuzziness: **Fuzzy** = strict 5-minute steps (1:02 → "one o'clock"); **Fuzzier** = adds "shortly after"/"nearly"
- Uppercase, day prefix, custom font/size/color, shadow
- Specials: replace the text in a time window (e.g. 12:00–13:00 "lunch")
- Start at login via a LaunchAgent (`~/Library/LaunchAgents/local.fuzzyclocksi.plist`) managed
  with `launchctl bootstrap` / `bootout`: the **Start at login** toggle in Settings, or
  `scripts/login-agent.sh install [app path] | uninstall | status`. Single-instance, so a
  duplicate launch just quits.
- `--print [HH:MM]` instead of an AppleScript dictionary

Out of scope: calendar events, chimes.

## Layout

| Path | What |
|---|---|
| `Sources/FuzzyCore/FuzzyClock.swift` | minute → phrase bucketing and hour selection (the core logic) |
| `Sources/FuzzyCore/Language.swift`, `LanguageStore.swift` | `.lproj` loading |
| `Sources/FuzzyClockSi/` | AppKit status item, SwiftUI settings |
| `Resources/Languages/English.lproj` | bundled English |
| `scripts/build-app.sh` | universal build + bundle + sign |
| `scripts/make-icon.swift`, `make-icns.sh` | draws the app icon in code → `Resources/AppIcon.icns` |
| `scripts/login-agent.sh` | LaunchAgent install/uninstall/status (bootstrap/bootout) |

## Notes on the original (reverse-engineering findings)

- Swift 5 / Xcode 11.3 app built 2019 against macOS 10.15 SDK, x86_64 only, Mac App Store build,
  bundles the Swift runtime dylibs + `SwiftDate.framework` (~9.4 MB total).
- Classes: `AppDelegate`, `MOTimeView` (custom status-item view using CALayers),
  `SpecialsDataSource`, `FontMenuItem`, `CurrentTime` (AppleScript command), `ITSwitch` toggles,
  `MrcsPreferencesWindow`.
- The phrasing is **data-driven**: each `<Lang>.lproj/Localizable.strings` has phrase templates
  (`"quarter to %@"`) plus `"quarter to ref" = "next" | "current"`, which says which hour the
  phrase names (German `"half past ref" = "next"` → 2:30 = "halb drei"). Also `"one o'clock"`
  for inflected forms ("ein Uhr"), `"midnight"`, and short day names.
- Minute buckets aren't in the data. Rounding to the nearest 5 minutes matches observation
  (10:48 → "ten to eleven"). The split :00 o'clock / :01–02 "shortly after" / :58–59 "nearly"
  is a best guess. Adjust `Phrase.forMinute` if it differs. To compare live:
  `osascript -e 'tell application "FuzzyTime" to current time'` vs `--print`.
- Original prefs live in `~/Library/Containers/com.mrcs.FuzzyTime/` (sandboxed).
