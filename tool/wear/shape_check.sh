#!/bin/bash
# Wear OS shape and font-size check (written for Google's Wear review of 19 Nov 2026, which
# rejected vc20004: capsules cut by the round edge, no scroll bar, text cut at large font sizes).
#
#   tool/wear/shape_check.sh <adb-serial> <outdir> [font_scale ...]     (default scales: 1.0 1.24)
#
# Needs the DEBUG wear build installed on a round Wear emulator (the capture hooks in
# MainActivity are debug only):  cd android && ./gradlew :wear:assembleDebug
#   adb -s <serial> install -r -g ../build/wear/outputs/apk/debug/wear-debug.apk
# Run it on BOTH sizes: WearOS_Small_Round (192dp, Pixel Watch 41mm) and WearOS_Large_Round (227dp).
#
# For each font scale it opens every screen, saves <outdir>/<scale>/NN-name.png and a contact
# sheet, then fails if any fixed (non-scrolling) screen draws in the outer 4% of the circle's
# radius. The emulator masks screenshots to the round display, so content in that ring is
# content at or past the edge. Lists are captured for the eye only (rows pass under the edge
# as they scroll); look at the sheet for cut text and for the scroll bar on the scrolled shots.
#
# This is the DEBUG build's check. The release bundle has its own: tool/wear/release_smoke.sh,
# run between the internal upload and the promote.
set -u
ADB=${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}
S=$1; OUT=$2; shift 2
SCALES=("$@"); [ ${#SCALES[@]} -eq 0 ] && SCALES=(1.0 1.24)
PKG=app.mentalmetal.wharfwod
ACT=$PKG/app.mentalmetal.wharfwod.wear.MainActivity
W=$($ADB -s "$S" shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1); W=${W%x*}
BEFORE=$($ADB -s "$S" shell settings get system font_scale | tr -d '\r')

shot() { # name wait extras...
  local name=$1 wait=$2; shift 2
  $ADB -s "$S" shell am force-stop $PKG
  $ADB -s "$S" shell am start -n $ACT "$@" >/dev/null 2>&1
  sleep "$wait"
  $ADB -s "$S" exec-out screencap -p > "$DIR/$name.png"
}
swipe() { # name fromY toY (fractions of the width, in eighths)
  $ADB -s "$S" shell input swipe $((W/2)) $((W*$2/8)) $((W/2)) $((W*$3/8)) 350; sleep 1.2
  $ADB -s "$S" exec-out screencap -p > "$DIR/$1.png"
}

fail=0
for scale in "${SCALES[@]}"; do
  DIR="$OUT/$scale"; mkdir -p "$DIR"
  $ADB -s "$S" shell settings put system font_scale "$scale"; sleep 2
  shot 01-home 3
  swipe 02-home-scroll1 5 3
  swipe 03-home-scroll2 5 2
  swipe 04-home-end 6 1
  shot 05-setup-fortime 3 --es route setup/fortime
  shot 06-setup-amrap 3 --es route setup/amrap
  shot 07-setup-emom 3 --es route setup/emom
  shot 08-setup-tabata 3 --es route setup/tabata
  shot 09-voice 3 --es route voice
  swipe 10-voice-end 6 1
  shot 11-health 3 --es route health
  swipe 12-health-end 6 1
  shot 13-live-prep 2 --es scene tabata:20:10:8
  shot 14-live-tabata 2.5 --es scene tabata:20:10:8 --es then run
  shot 15-live-fortime 2.5 --es scene fortime:1200:1 --es then run
  shot 16-live-amrap 2.5 --es scene amrap:600 --es then run
  shot 17-live-emom 2.5 --es scene emom:60:10 --es then run
  shot 18-paused-tabata 2.5 --es scene tabata:20:10:8 --es then pause
  shot 19-paused-fortime 2.5 --es scene fortime:1200:1 --es then pause
  shot 20-done-fortime 2.5 --es scene fortime:1200:1 --es then finish
  shot 21-done-amrap 2.5 --es scene amrap:600 --es then stop
  shot 22-done-tabata 2.5 --es scene tabata:20:10:8 --es then stop
  $ADB -s "$S" shell am force-stop $PKG
  R=$((W/2)); IN=$((R*96/100))
  for f in "$DIR"/0[5-8]-*.png "$DIR"/1[3-9]-*.png "$DIR"/2?-*.png; do
    n=$(magick "$f" -alpha off \( -size ${W}x${W} xc:black -fill white -draw "circle $R,$R $R,0" -fill black -draw "circle $R,$R $R,$((R-IN))" \) \
        -compose multiply -composite -colorspace gray -threshold 12% -format "%[fx:round(mean*w*h)]" info:)
    if [ "$n" != "0" ]; then echo "EDGE CONTENT font $scale $(basename "$f"): $n px"; fail=1; fi
  done
  magick montage "$DIR"/[0-9]*.png -background "#555" -tile 6x4 -geometry 256x256+4+4 "$OUT/sheet-$scale.png" 2>/dev/null
  echo "font $scale: $(ls "$DIR" | wc -l | tr -d ' ') screens, sheet $OUT/sheet-$scale.png"
done
$ADB -s "$S" shell settings put system font_scale "$BEFORE"

# Flows: after DONE the app must show a screen. On the release build of 2.5.2 it showed a black one
# (the back stack had been emptied), which no single-screen capture can see.
bright() { magick "$1" -alpha off -colorspace gray -threshold 12% -format "%[fx:round(100*mean)]" info:; }
tapf() { $ADB -s "$S" shell input tap $((W*$1/1000)) $((W*$2/1000)); sleep "${3:-1.5}"; }
DIR="$OUT/flows"; mkdir -p "$DIR"
# 1. Opened straight onto a workout (nothing under it): stop, DONE, expect Home.
shot done-direct-end 2.5 --es scene amrap:600 --es then stop
tapf 640 760 2; $ADB -s "$S" exec-out screencap -p > "$DIR/done-direct-after.png"
# 2. From Home: first tile, START, skip get ready, PAUSE, hold to stop, DONE, expect setup.
shot from-home 3
tapf 330 380 2; tapf 500 730 2.5; tapf 500 400 1.5; tapf 500 760 1.2
$ADB -s "$S" shell input swipe $((W*360/1000)) $((W*760/1000)) $((W*361/1000)) $((W*761/1000)) 1500; sleep 1.8
$ADB -s "$S" exec-out screencap -p > "$DIR/from-home-end.png"
tapf 640 760 2; $ADB -s "$S" exec-out screencap -p > "$DIR/from-home-after.png"
$ADB -s "$S" shell am force-stop $PKG
for f in done-direct-after from-home-after; do
  b=$(bright "$DIR/$f.png")
  if [ "$b" -lt 2 ]; then echo "BLANK SCREEN after DONE: $f.png"; fail=1; else echo "after DONE ($f): a screen is showing ($b% lit)"; fi
done
# 3. The Back button and the wake lock (26 Nov 2026). Back popped the live screen to setup while
# the timer ran on behind it, and with the screen off nothing kept the processor ticking (an
# emulator never suspends, so only the lock itself can be checked here, not the missed beeps).
words() { $ADB -s "$S" shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; $ADB -s "$S" shell cat /sdcard/ui.xml | grep -oE 'text="[^"]+"' | tr '\n' ' '; }
locks() { $ADB -s "$S" shell dumpsys power | grep -c "PARTIAL_WAKE_LOCK.*WharfWOD:timer"; }
expect() { # what, got, wanted
  if [ "$2" = "$3" ]; then echo "$1: ok"; else echo "FLOW $1: got '$2', wanted '$3'"; fail=1; fi
}
has() { case "$2" in *"$3"*) echo "$1: ok" ;; *) echo "FLOW $1: no '$3' in: $2"; fail=1 ;; esac; }
expect "no workout, no wake lock" "$(locks)" 0
$ADB -s "$S" shell am start -n $ACT --es scene emom:60:10 --es then run >/dev/null 2>&1; sleep 3
expect "running holds the wake lock" "$(locks)" 1
$ADB -s "$S" shell input keyevent KEYCODE_BACK; sleep 1.5
has "Back mid-workout stays on the timer" "$(words)" 'text="PAUSE"'
$ADB -s "$S" shell input keyevent KEYCODE_SLEEP; sleep 5
expect "screen off keeps the wake lock" "$(locks)" 1
$ADB -s "$S" shell input keyevent KEYCODE_WAKEUP; sleep 1.5
tapf 500 760 1.5
expect "paused lets go of the wake lock" "$(locks)" 0
$ADB -s "$S" shell input keyevent KEYCODE_BACK; sleep 1.5
has "Back while paused stays paused" "$(words)" 'text="RESUME"'
tapf 640 760 1.5
expect "resumed holds it again" "$(locks)" 1
tapf 500 760 1.2
$ADB -s "$S" shell input swipe $((W*360/1000)) $((W*760/1000)) $((W*361/1000)) $((W*761/1000)) 1500; sleep 1.8
expect "stopped lets go of the wake lock" "$(locks)" 0
has "the end screen shows" "$(words)" 'text="DONE"'
$ADB -s "$S" shell input keyevent KEYCODE_BACK; sleep 2
has "Back on the end screen is DONE" "$(words)" 'text="EMOM"'
$ADB -s "$S" shell am force-stop $PKG
[ $fail = 0 ] && echo "PASS: nothing in the edge ring on any fixed screen" || echo "FAIL"
exit $fail
