#!/usr/bin/env bash
# Store set frame 1 (23 Nov 2026): Home with a mixed Today's WOD card, on an
# iPhone simulator at 9:41 (integration_test/store_home_test.dart prints one
# MARK_ line; this grabs the display then).
#
#   UDID=<booted iphone> OUT=<dir> [STORE_SESSION=all4|classic] tool/capture_store_home.sh
#
# Output: $OUT/store-home-<session>.png at the simulator's native size
# (1320x2868 on an iPhone 17 Pro Max, the size the D6 generator takes).
set -euo pipefail
cd "$(dirname "$0")/.."

UDID="${UDID:?set UDID to a booted iPhone simulator}"
OUT="${OUT:?set OUT}"
SESSION="${STORE_SESSION:-all4}"
export LANG=en_US.UTF-8
mkdir -p "$OUT"

xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true
xcrun simctl uninstall "$UDID" app.mentalmetal.wharfwod >/dev/null 2>&1 || true

fvm flutter test integration_test/store_home_test.dart -d "$UDID" \
  --dart-define=STORE_SESSION="$SESSION" 2>&1 | while IFS= read -r line; do
  printf '%s\n' "$line"
  if [[ "$line" =~ MARK_([a-z0-9-]+) ]]; then
    sleep 0.5
    xcrun simctl io "$UDID" screenshot "$OUT/${BASH_REMATCH[1]}.png" >/dev/null 2>&1
    echo "captured $OUT/${BASH_REMATCH[1]}.png"
  fi
done
