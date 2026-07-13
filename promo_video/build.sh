#!/bin/bash
# The Wharf WOD Timer portrait promo (1290x2796, ~29s). Cuts straight from
# work/raw.mov by timestamp; text via overlay PNGs (mktext.py); phonk bed.
set -euo pipefail
PV="$(cd "$(dirname "$0")" && pwd)"
APP="$(cd "$PV/.." && pwd)"
ICON_SRC="$APP/assets/icons/app_icon_1024.png"
MUSIC="$PV/music/phonk_gym_mondamusic.mp3"
RAW="$PV/work/raw.mov"
TXT="$PV/work/txt"
S="$PV/work/scenes"; rm -rf "$S"; mkdir -p "$S" "$PV/out"
W=1290; H=2796; FPS=30; DARK="0x050510"

norm="setsar=1,format=yuv420p,fps=$FPS"

python3 "$PV/mktext.py"

# Rounded icon (squircle mask) once.
ICON="$PV/work/icon_round.png"
ffmpeg -nostdin -loglevel error -i "$ICON_SRC" -i "$TXT/iconmask.png" \
  -filter_complex "[0:v]scale=520:520,format=rgba[i];[1:v]format=gray[m];[i][m]alphamerge" \
  -frames:v 1 "$ICON" -y

live_scene(){ # ss t capPNG out
  ffmpeg -nostdin -loglevel error -ss "$1" -t "$2" -i "$RAW" -i "$3" \
    -filter_complex "[0:v]scale=$W:$H:flags=lanczos,setsar=1[b];[b][1:v]overlay=0:0:format=auto:eof_action=repeat,$norm[v]" \
    -map "[v]" -c:v libx264 -crf 16 -preset veryfast -an "$4" -y
}

echo "[s1] title"; ffmpeg -nostdin -loglevel error \
  -f lavfi -t 2.6 -i "color=c=$DARK:s=${W}x${H}:r=$FPS" \
  -loop 1 -t 2.6 -i "$ICON" -loop 1 -t 2.6 -i "$TXT/title_overlay.png" \
  -filter_complex "[1:v]format=rgba,fade=t=in:st=0.0:d=0.6:alpha=1[ic];[0:v][ic]overlay=(W-w)/2:760[bg];[2:v]format=rgba,fade=t=in:st=0.45:d=0.6:alpha=1[tx];[bg][tx]overlay=0:0:format=auto[c];[c]fade=t=in:st=0:d=0.35,$norm[v]" \
  -map "[v]" -c:v libx264 -crf 16 -preset veryfast -an "$S/s1.mp4" -y

echo "[s2] home";    live_scene 50.6  2.4 "$TXT/c_home.png"   "$S/s2.mp4"
echo "[s3] setup";   live_scene 54.0  3.6 "$TXT/c_setup.png"  "$S/s3.mp4"
echo "[s4] count";   live_scene 64.4  4.0 "$TXT/c_count.png"  "$S/s4.mp4"
echo "[s5] work";    live_scene 68.4  5.6 "$TXT/c_go.png"     "$S/s5.mp4"
echo "[s6] tabata";  live_scene 118.6 6.0 "$TXT/c_tabata.png" "$S/s6.mp4"
echo "[s7] done";    live_scene 82.2  3.0 "$TXT/c_done.png"   "$S/s7.mp4"

echo "[s8] end"; ffmpeg -nostdin -loglevel error \
  -f lavfi -t 3.4 -i "color=c=$DARK:s=${W}x${H}:r=$FPS" \
  -loop 1 -t 3.4 -i "$ICON" -loop 1 -t 3.4 -i "$TXT/end_overlay.png" \
  -filter_complex "[1:v]scale=420:420[ic];[0:v][ic]overlay=(W-w)/2:940[bg];[bg][2:v]overlay=0:0:format=auto[c];[c]fade=t=out:st=3.0:d=0.4,$norm[v]" \
  -map "[v]" -c:v libx264 -crf 16 -preset veryfast -an "$S/s8.mp4" -y

echo "[+] crossfade"; F=0.4; N=8
durs=(); for i in $(seq 1 $N); do durs+=("$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$S/s$i.mp4")"); done
inputs=""; for i in $(seq 1 $N); do inputs+=" -i $S/s$i.mp4"; done
fc=""; prev="0:v"; acc=${durs[0]}
for idx in $(seq 1 $((N-1))); do
  off=$(python3 -c "print(round($acc - $F,3))"); out="x$idx"
  fc+="[$prev][$idx:v]xfade=transition=fade:duration=$F:offset=$off[$out];"
  acc=$(python3 -c "print(round($acc + ${durs[$idx]} - $F,3))"); prev="$out"
done
fc="${fc%;}"
ffmpeg -nostdin -loglevel error $inputs -filter_complex "$fc" -map "[$prev]" \
  -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p "$S/video_noaudio.mp4" -y

VID=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$S/video_noaudio.mp4")
echo "[+] mux music (video ${VID}s)"
ffmpeg -nostdin -loglevel error -i "$S/video_noaudio.mp4" -i "$MUSIC" \
  -filter_complex "[1:a]atrim=0:$VID,afade=t=in:st=0:d=0.5,afade=t=out:st=$(python3 -c "print(round($VID-1.4,2))"):d=1.4,volume=0.9[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -shortest "$PV/out/promo.mp4" -y

ffmpeg -nostdin -loglevel error -ss 1.2 -i "$S/s5.mp4" -frames:v 1 -q:v 3 "$PV/out/promo-poster.jpg" -y
echo "[done] $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$PV/out/promo.mp4")s -> out/promo.mp4 + promo-poster.jpg"
