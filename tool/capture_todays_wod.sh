#!/usr/bin/env bash
# Today's WOD (2.6.0): captures the real build's screens with a real session
# running (integration_test/todays_wod_tour_test.dart prints MARK_<name>
# lines; this takes a screenshot at each one).
#
#   tool/capture_todays_wod.sh ios       # iPhone simulator  -> ios-<name>.png
#   tool/capture_todays_wod.sh ipad      # iPad simulator    -> ipad-<name>.png
#   tool/capture_todays_wod.sh android   # Android emulator  -> android-<name>.png
#   tool/capture_todays_wod.sh single    # the four timers on their own -> ios-single-*.png
#   tool/capture_todays_wod.sh cues      # the cue run, log to OUT/cues-ios.log
#
# UDID picks the simulator (boot it first; IPAD_UDID for ipad), SERIAL the
# emulator, OUT the folder for the PNGs. Each run is a clean install, so
# settings and setups are the defaults. Landscape shots are named
# <platform>-landscape-<name>.png.
set -euo pipefail

cd "$(dirname "$0")/.."

WHICH="${1:-ios}"
UDID="${UDID:-8AB9BDB8-113C-48BE-82E7-553111C6F72B}"
IPAD_UDID="${IPAD_UDID:-}"
SERIAL="${SERIAL:-emulator-5564}"
OUT="${OUT:-$(cd .. && pwd)/previews/wharf-real}"
BUNDLE_ID=app.mentalmetal.wharfwod
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"

# pod install needs a UTF-8 locale from a tool shell.
export LANG=en_US.UTF-8
mkdir -p "$OUT"

shoot() { # platform device name
  local file="$OUT/$1-$3.png"
  if [[ "$1" == "android" ]]; then
    "$ADB" -s "$2" exec-out screencap -p > "$file"
  else
    xcrun simctl io "$2" screenshot "$file" >/dev/null 2>&1
    # An iPhone simulator screenshot is in the panel's own orientation:
    # turn the sideways shots upright (needs ImageMagick). An iPad app that
    # supports multitasking ignores the requested orientation, so its
    # landscape-* shots are upright duplicates: delete them.
    if [[ "$1" == ios && "$3" == landscape-* ]] && command -v magick >/dev/null; then
      magick "$file" -rotate 90 "$file"
    fi
  fi
  echo "captured $file"
}

tour() { # platform device test
  if [[ "$1" == "android" ]]; then
    "$ADB" -s "$2" uninstall "$BUNDLE_ID" >/dev/null 2>&1 || true
    # A fresh install would show Android's one-time "Viewing full screen"
    # card over every live screen: mark it seen on the capture emulator.
    "$ADB" -s "$2" shell settings put secure immersive_mode_confirmations confirmed
  else
    xcrun simctl status_bar "$2" override --time 9:41 --batteryState charged \
      --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true
    xcrun simctl uninstall "$2" "$BUNDLE_ID" >/dev/null 2>&1 || true
  fi
  fvm flutter test "$3" -d "$2" 2>&1 | while IFS= read -r line; do
    printf '%s\n' "$line"
    if [[ "$line" =~ MARK_([a-z0-9-]+) && "$3" != *cues* ]]; then
      sleep 0.5
      shoot "$1" "$2" "${BASH_REMATCH[1]}"
    fi
  done
}

case "$WHICH" in
  ios) tour ios "$UDID" integration_test/todays_wod_tour_test.dart ;;
  ipad)
    [[ -n "$IPAD_UDID" ]] || { echo "set IPAD_UDID" >&2; exit 2; }
    tour ipad "$IPAD_UDID" integration_test/todays_wod_tour_test.dart
    ;;
  android) tour android "$SERIAL" integration_test/todays_wod_tour_test.dart ;;
  single) tour ios "$UDID" integration_test/todays_wod_single_timers_test.dart ;;
  cues)
    tour ios "$UDID" integration_test/todays_wod_cues_test.dart \
      | tee "$OUT/cues-ios.log" | grep -E 'MARK_|\[wharfwod\] cue|passed|failed'
    ;;
  *) echo "usage: $0 [ios|ipad|android|single|cues]" >&2; exit 2 ;;
esac
