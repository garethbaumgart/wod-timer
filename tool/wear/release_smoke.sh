#!/bin/bash
# Smoke of the EXACT Wear OS release bundle, to run between `wear_internal` and
# `wear_promote` (written 26 Nov 2026 for 2.7.0, vc20007; 2.5.2's vc20005 showed a black
# screen after DONE that only the release build had).
#
#   tool/wear/release_smoke.sh <adb-serial> <outdir> [bundle.aab]
#
# The bundle defaults to the one the lane just uploaded
# (build/wear/outputs/bundle/release/wear-release.aab). It is turned into a universal APK
# with bundletool, installed fresh, and driven with real taps, keys and holds: the release
# build has none of the debug capture hooks shape_check.sh uses. Controls are tapped by the
# words on them (ui_centre.py), so For Time's two-button row and EMOM's single PAUSE both work.
# Run it on BOTH round emulators (WearOS_Small_Round_API34, WearOS_Large_Round_API34).
# Needs JAVA_HOME (Android Studio's jbr), bundletool and ImageMagick.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
ADB=${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}
S=$1; OUT=$2; AAB=${3:-$ROOT/build/wear/outputs/bundle/release/wear-release.aab}
mkdir -p "$OUT"
PKG=app.mentalmetal.wharfwod
ACT=$PKG/app.mentalmetal.wharfwod.wear.MainActivity
WANT_NAME=$(grep -E '^version:' "$ROOT/pubspec.yaml" | sed -E 's/version: *([0-9.]+).*/\1/')
fail=0

rm -rf "$OUT/apks" "$OUT/wear.apks"
bundletool build-apks --bundle="$AAB" --output="$OUT/wear.apks" --mode=universal >/dev/null 2>&1 \
  || { echo "FAIL: bundletool could not build from $AAB"; exit 1; }
unzip -o -q "$OUT/wear.apks" -d "$OUT/apks"
APK="$OUT/apks/universal.apk"
echo "bundle: $AAB ($(shasum -a 256 "$AAB" | cut -c1-12))"

$ADB -s "$S" uninstall $PKG >/dev/null 2>&1
$ADB -s "$S" install -r -g "$APK" | tail -1
W=$($ADB -s "$S" shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1); W=${W%x*}
$ADB -s "$S" logcat -c

cap() { $ADB -s "$S" exec-out screencap -p > "$OUT/$1.png"; }
tapf() { $ADB -s "$S" shell input tap $((W*$1/1000)) $((W*$2/1000)); sleep "${3:-1.5}"; }
words() { $ADB -s "$S" shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; $ADB -s "$S" shell cat /sdcard/ui.xml | grep -oE 'text="[^"]+"' | tr '\n' ' '; }
locks() { $ADB -s "$S" shell dumpsys power | grep -c "PARTIAL_WAKE_LOCK.*WharfWOD:timer"; }
bright() { magick "$1" -alpha off -colorspace gray -threshold 12% -format "%[fx:round(100*mean)]" info:; }
expect() { if [ "$2" = "$3" ]; then echo "$1: ok"; else echo "FLOW $1: got '$2', wanted '$3'"; fail=1; fi; }
has() { case "$2" in *"$3"*) echo "$1: ok" ;; *) echo "FLOW $1: no '$3' in: $2"; fail=1 ;; esac; }
centre() { # text -> "x y" of the first node with exactly that text
  $ADB -s "$S" shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  $ADB -s "$S" exec-out cat /sdcard/ui.xml | python3 "$HERE/ui_centre.py" "$1"
}
tapword() { # text [wait]
  local c; c=$(centre "$1")
  if [ -z "$c" ]; then echo "FLOW no '$1' on screen to tap: $(words)"; fail=1; return; fi
  $ADB -s "$S" shell input tap $c; sleep "${2:-1.5}"
}
holdword() { # text
  local c; c=$(centre "$1")
  if [ -z "$c" ]; then echo "FLOW no '$1' on screen to hold: $(words)"; fail=1; return; fi
  $ADB -s "$S" shell input swipe $c $c 1600; sleep 1.8
}

VN=$($ADB -s "$S" shell dumpsys package $PKG | grep -oE 'versionName=[^ ]+' | head -1 | tr -d '\r')
VC=$($ADB -s "$S" shell dumpsys package $PKG | grep -oE 'versionCode=[0-9]+' | head -1 | tr -d '\r')
DBG=$($ADB -s "$S" shell dumpsys package $PKG | grep -c 'DEBUGGABLE')
echo "installed: $VN $VC on a ${W}px round screen"
expect "version name is the pubspec's" "$VN" "versionName=$WANT_NAME"
expect "not a debug build" "$DBG" 0

$ADB -s "$S" shell am start -n $ACT >/dev/null 2>&1; sleep 5
cap 01-home; H=$(words); echo "Home: $H"
has "Home shows FOR TIME" "$H" 'FOR TIME'
has "Home shows AMRAP" "$H" 'AMRAP'
has "Home shows EMOM" "$H" 'EMOM'
has "Home shows TABATA" "$H" 'TABATA'
expect "no workout, no wake lock" "$(locks)" 0

# 1. EMOM: run, Back, screen off, pause, Back, resume, stop, DONE.
tapword EMOM 2.5; cap 02-emom-setup
tapword START 2.5; cap 03-get-ready
tapf 500 400 2; cap 04-emom-running
has "the EMOM runs" "$(words)" 'text="PAUSE"'
expect "running holds the wake lock" "$(locks)" 1
$ADB -s "$S" shell input keyevent KEYCODE_BACK; sleep 1.5
has "Back mid-workout stays on the timer" "$(words)" 'text="PAUSE"'
expect "Back mid-workout keeps the wake lock" "$(locks)" 1
$ADB -s "$S" shell input keyevent KEYCODE_SLEEP; sleep 6
expect "screen off keeps the wake lock" "$(locks)" 1
$ADB -s "$S" shell input keyevent KEYCODE_WAKEUP; sleep 2
has "after waking the timer is still running" "$(words)" 'text="PAUSE"'
tapword PAUSE 1.5; cap 05-emom-paused
has "PAUSE pauses" "$(words)" 'text="RESUME"'
expect "paused lets go of the wake lock" "$(locks)" 0
$ADB -s "$S" shell input keyevent KEYCODE_BACK; sleep 1.5
has "Back while paused stays paused" "$(words)" 'text="RESUME"'
tapword RESUME 1.5
has "RESUME runs again" "$(words)" 'text="PAUSE"'
expect "resumed holds it again" "$(locks)" 1
tapword PAUSE 1.5
holdword "HOLD TO STOP"; cap 06-emom-end
expect "stopped lets go of the wake lock" "$(locks)" 0
has "the end screen shows" "$(words)" 'text="DONE"'
tapword DONE 2; cap 07-after-done
b=$(bright "$OUT/07-after-done.png")
if [ "$b" -lt 2 ]; then echo "BLANK SCREEN after DONE"; fail=1; else echo "after DONE: a screen is showing ($b% lit)"; fi
has "DONE lands on the setup" "$(words)" 'text="START"'
$ADB -s "$S" shell input keyevent KEYCODE_BACK; sleep 2; cap 08-back-home
has "Back from setup is Home" "$(words)" 'TABATA'

# 2. For Time: run, FINISH, the end screen, then Back on the end screen (it is DONE).
tapword "FOR TIME" 2.5
tapword START 2.5; tapf 500 400 2.5; cap 09-fortime-running
has "For Time runs" "$(words)" 'text="FINISH"'
expect "For Time holds the wake lock" "$(locks)" 1
tapword FINISH 2; cap 10-fortime-end
has "FINISH ends on the end screen" "$(words)" 'text="DONE"'
expect "finished lets go of the wake lock" "$(locks)" 0
$ADB -s "$S" shell input keyevent KEYCODE_BACK; sleep 2; cap 11-fortime-after-back
b=$(bright "$OUT/11-fortime-after-back.png")
if [ "$b" -lt 2 ]; then echo "BLANK SCREEN after Back on the end screen"; fail=1; else echo "Back on the end screen: a screen is showing ($b% lit)"; fi
has "Back on the end screen is DONE" "$(words)" 'text="START"'
$ADB -s "$S" shell input keyevent KEYCODE_BACK; sleep 2

# 3. The other two tiles open their own setups.
for t in AMRAP TABATA; do
  tapword $t 2.2
  has "$t tile opens its setup" "$(words)" 'text="START"'
  $ADB -s "$S" shell input keyevent KEYCODE_BACK; sleep 1.5
done
cap 12-home-again
has "back on Home at the end" "$(words)" 'EMOM'

CR=$($ADB -s "$S" logcat -d -b crash | grep -c "$PKG")
expect "no crash in the log" "$CR" 0
$ADB -s "$S" shell am force-stop $PKG
magick montage "$OUT"/[01]*.png -background "#555" -tile 6x2 -geometry 256x256+4+4 "$OUT/sheet.png" 2>/dev/null
[ $fail = 0 ] && echo "PASS: release smoke of $VN $VC on $S, sheet $OUT/sheet.png" || echo "FAIL: release smoke on $S"
exit $fail
