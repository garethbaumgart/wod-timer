#!/usr/bin/env bash
# PROTOTYPE ONLY ("Today's WOD", 20 Nov 2026): captures the preview
# screenshots from the real app on a booted iOS simulator.
#
#   tool/preview/capture_todays_wod.sh            # both halves
#   tool/preview/capture_todays_wod.sh now        # now-01..03: the app as it ships
#   tool/preview/capture_todays_wod.sh proposed   # 01..09: the prototype screens
#
# UDID picks the simulator (boot it first), OUT the folder for the PNGs.
# Each half is a clean install, so settings and setups are the defaults.
# The tours print MARK_<file> lines; this takes a screenshot at each one.
set -euo pipefail

cd "$(dirname "$0")/../.."

UDID="${UDID:-8AB9BDB8-113C-48BE-82E7-553111C6F72B}"
OUT="${OUT:-$(cd .. && pwd)/previews/wharf}"
WHICH="${1:-all}"
BUNDLE_ID=app.mentalmetal.wharfwod

# pod install needs a UTF-8 locale from a tool shell.
export LANG=en_US.UTF-8

mkdir -p "$OUT"
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3

tour() {
  xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  fvm flutter test "$1" -d "$UDID" 2>&1 | while IFS= read -r line; do
    printf '%s\n' "$line"
    if [[ "$line" =~ MARK_([a-z0-9-]+) ]]; then
      sleep 0.7
      xcrun simctl io "$UDID" screenshot "$OUT/${BASH_REMATCH[1]}.png" >/dev/null 2>&1
      echo "captured $OUT/${BASH_REMATCH[1]}.png"
    fi
  done
}

case "$WHICH" in
  now) tour integration_test/todays_wod_now_test.dart ;;
  proposed) tour integration_test/todays_wod_preview_test.dart ;;
  all)
    tour integration_test/todays_wod_now_test.dart
    tour integration_test/todays_wod_preview_test.dart
    ;;
  *) echo "usage: $0 [now|proposed|all]" >&2; exit 2 ;;
esac
