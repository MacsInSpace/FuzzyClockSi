#!/bin/zsh
# Install/remove the start-at-login LaunchAgent using launchctl bootstrap/bootout.
#   scripts/login-agent.sh install [path/to/Fuzzy Clock Si.app]   (default: /Applications)
#   scripts/login-agent.sh uninstall
#   scripts/login-agent.sh status
set -euo pipefail

LABEL="local.fuzzyclocksi"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

case "${1:-}" in
  install)
    APP="${2:-/Applications/Fuzzy Clock Si.app}"
    EXE="${APP:A}/Contents/MacOS/FuzzyClockSi"
    [[ -x "$EXE" ]] || { echo "Not found: $EXE" >&2; exit 1; }
    mkdir -p "${PLIST:h}"
    cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$EXE</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><false/>
    <key>ProcessType</key><string>Interactive</string>
    <key>LimitLoadToSessionType</key><string>Aqua</string>
</dict>
</plist>
PLIST
    plutil -lint "$PLIST" >/dev/null
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
    launchctl bootstrap "$DOMAIN" "$PLIST"
    echo "Installed and started: $PLIST"
    ;;
  uninstall)
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
    rm -f "$PLIST"
    echo "Removed: $PLIST"
    ;;
  status)
    if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
      launchctl print "$DOMAIN/$LABEL" | grep -E '^\s*(state|pid|program) ='
    else
      echo "Not loaded"
    fi
    [[ -f "$PLIST" ]] && echo "Plist: $PLIST" || echo "No plist"
    ;;
  *)
    echo "usage: $0 install [app path] | uninstall | status" >&2; exit 2 ;;
esac
