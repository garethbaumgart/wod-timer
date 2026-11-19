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
[ $fail = 0 ] && echo "PASS: nothing in the edge ring on any fixed screen" || echo "FAIL"
exit $fail
