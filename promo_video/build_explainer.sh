#!/usr/bin/env bash
# Assemble the Wharf WOD landscape kinetic explainer: frames (explainer.py) +
# phonk-gym music bed + the app's own GO / 3-2-1 / complete cues, synced to the
# scene beats. No VO. Output: out/wharf_explainer_1080p.mp4 + poster.
set -euo pipefail
cd "$(dirname "$0")"

FPS=30
TOTAL=36.1
MUSIC=music/stomp_drum_percussion_513744.mp3
AUD=../build/flutter_assets/assets/audio
mkdir -p out

# scene starts (s): hook 0 | nah 4.6 | yell 6.4 | modes 9.8 | glance 19.4 | trio 23.8 | cta 30.1
GO_MS=7600        # GO burst in the yell scene
CD3_MS=400; CD2_MS=1100; CD1_MS=1800   # 3-2-1 over the hook intro
DONE_MS=30400     # complete ding at the CTA

echo "[1/3] frames -> silent video"
ffmpeg -y -v error -framerate $FPS -i frames_ex/%05d.png \
  -c:v libx264 -pix_fmt yuv420p -preset medium -crf 18 -t $TOTAL out/ex_silent.mp4

echo "[2/3] mix audio (music bed + app cues)"
# build input list + filter, only including SFX that exist
INPUTS=(-i "$MUSIC")
FILTER="[0:a]atrim=0:${TOTAL},volume=0.62,afade=t=in:d=1.2,afade=t=out:st=$(python3 -c "print($TOTAL-2.8)"):d=2.8[m];"
MIX="[m]"
idx=1
add_sfx () { # file, delay_ms, vol, label
  local f="$1" ms="$2" vol="$3" lab="$4"
  if [ -f "$f" ]; then
    INPUTS+=(-i "$f")
    FILTER+="[${idx}:a]adelay=${ms}|${ms},volume=${vol}[${lab}];"
    MIX+="[${lab}]"
    idx=$((idx+1))
  fi
}
# app voice cues removed per request — music bed only
# add_sfx "$AUD/countdown_3.m4a" $CD3_MS 0.8 c3
# add_sfx "$AUD/countdown_2.m4a" $CD2_MS 0.8 c2
# add_sfx "$AUD/countdown_1.m4a" $CD1_MS 0.8 c1
# add_sfx "$AUD/go.m4a"          $GO_MS  1.2 go
# add_sfx "$AUD/complete.m4a"    $DONE_MS 1.0 dn
NIN=$idx
FILTER+="${MIX}amix=inputs=${NIN}:normalize=0,alimiter=limit=0.97[a]"

ffmpeg -y -v error "${INPUTS[@]}" -filter_complex "$FILTER" -map "[a]" -t $TOTAL out/ex_audio.wav

echo "[3/3] mux -> final"
ffmpeg -y -v error -i out/ex_silent.mp4 -i out/ex_audio.wav \
  -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -shortest out/wharf_explainer_1080p.mp4
ffmpeg -y -v error -sseof -1.5 -i out/wharf_explainer_1080p.mp4 -frames:v 1 -q:v 3 out/wharf_explainer_poster.jpg

echo "done: $(ffprobe -v quiet -show_entries format=duration -of csv=p=0 out/wharf_explainer_1080p.mp4)s -> out/wharf_explainer_1080p.mp4"
