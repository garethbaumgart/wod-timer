#!/bin/bash
# The Wharf WOD Timer portrait promo (1290x2796, ~29s).
# 2026-07-13 rework — sound-first: the app's own coach (Major) counts the
# on-screen 3-2-1 and yells GO the exact frame the timer flips to WORK, with
# the epic-rock bed hard-cutting to its drop on the same frame. Hard cuts
# (no crossfades) so every voice cue lands frame-accurate. Wharfie rides the
# caption pills (mktext.py).
set -euo pipefail
PV="$(cd "$(dirname "$0")" && pwd)"
APP="$(cd "$PV/.." && pwd)"
ICON_SRC="$APP/assets/icons/app_icon_1024.png"
MUSIC="$PV/music/motivation_epic_rock_alexgrohl.mp3"
VOICE="$APP/assets/audio/major"
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

# ---- scene timeline (hard cuts; keep these in sync with the cue math below)
D1=1.8                 # s1 title
S2_SS=64.55; D2=3.45   # s2 countdown 3-2-1 (digit flips at raw 64.9/65.9/66.9)
S3_SS=68.00; D3=4.60   # s3 GO — WORK flip is the first frame of this scene
S4_SS=50.60; D4=2.80   # s4 four-timer menu
S5_SS=54.40; D5=3.60   # s5 AMRAP setup picker
S6_SS=119.90; D6=5.60  # s6 tabata WORK 3-2-1 -> REST flip at raw ~122.0
S7_SS=83.20; D7=3.00   # s7 Finished! card
D8=3.75                # s8 end card

echo "[s1] title"; ffmpeg -nostdin -loglevel error \
  -f lavfi -t $D1 -i "color=c=$DARK:s=${W}x${H}:r=$FPS" \
  -loop 1 -t $D1 -i "$TXT/title_overlay.png" \
  -filter_complex "[1:v]format=rgba,fade=t=in:st=0.1:d=0.45:alpha=1[tx];[0:v][tx]overlay=0:0:format=auto[c];[c]fade=t=in:st=0:d=0.25,$norm[v]" \
  -map "[v]" -c:v libx264 -crf 16 -preset veryfast -an "$S/s1.mp4" -y

echo "[s2] countdown"; ffmpeg -nostdin -loglevel error -ss $S2_SS -t $D2 -i "$RAW" \
  -filter_complex "[0:v]scale=$W:$H:flags=lanczos,$norm[v]" \
  -map "[v]" -c:v libx264 -crf 16 -preset veryfast -an "$S/s2.mp4" -y

echo "[s3] GO"; ffmpeg -nostdin -loglevel error -ss $S3_SS -t $D3 -i "$RAW" \
  -loop 1 -t $D3 -i "$TXT/go_slam.png" -loop 1 -t $D3 -i "$TXT/c_go.png" \
  -f lavfi -t $D3 -i "color=c=0x00FF88:s=${W}x${H}:r=$FPS" \
  -filter_complex "\
[0:v]scale=$W:$H:flags=lanczos,setsar=1[b];\
[3:v]format=rgba,fade=t=out:st=0:d=0.15:alpha=1[fl];\
[b][fl]overlay=0:0:format=auto:enable='lt(t,0.16)'[f0];\
[1:v]format=rgba,fade=t=out:st=1.0:d=0.18:alpha=1[go];\
[f0][go]overlay=0:0:format=auto:enable='lt(t,1.2)'[f1];\
[2:v]format=rgba,fade=t=in:st=1.25:d=0.3:alpha=1[cap];\
[f1][cap]overlay=0:0:format=auto:enable='gte(t,1.25)',$norm[v]" \
  -map "[v]" -c:v libx264 -crf 16 -preset veryfast -an "$S/s3.mp4" -y

echo "[s4] menu";   live_scene $S4_SS $D4 "$TXT/c_timers.png" "$S/s4.mp4"
echo "[s5] setup";  live_scene $S5_SS $D5 "$TXT/c_setup.png" "$S/s5.mp4"
echo "[s6] tabata"; live_scene $S6_SS $D6 "$TXT/c_tabata.png" "$S/s6.mp4"
echo "[s7] done";   live_scene $S7_SS $D7 "$TXT/c_done.png" "$S/s7.mp4"

echo "[s8] end"; ffmpeg -nostdin -loglevel error \
  -f lavfi -t $D8 -i "color=c=$DARK:s=${W}x${H}:r=$FPS" \
  -loop 1 -t $D8 -i "$TXT/end_overlay.png" \
  -filter_complex "[1:v]format=rgba,fade=t=in:st=0.05:d=0.3:alpha=1[tx];[0:v][tx]overlay=0:0:format=auto[c];[c]fade=t=out:st=3.3:d=0.45,$norm[v]" \
  -map "[v]" -c:v libx264 -crf 16 -preset veryfast -an "$S/s8.mp4" -y

echo "[+] hard-cut concat"
fc=""; inputs=""
for i in 1 2 3 4 5 6 7 8; do inputs+=" -i $S/s$i.mp4"; fc+="[$((i-1)):v]"; done
ffmpeg -nostdin -loglevel error $inputs -filter_complex "${fc}concat=n=8:v=1:a=0[v]" \
  -map "[v]" -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p "$S/video_noaudio.mp4" -y

VID=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$S/video_noaudio.mp4")
echo "[+] audio (video ${VID}s)"

# ---- cue offsets (video seconds -> ms), derived from the scene table above
GO_AT=$(python3 -c "print(round($D1+$D2,3))")                       # 5.25
T3=$(python3 -c "print(int(($D1+(64.90-$S2_SS))*1000))")            # digit 3
T2=$(python3 -c "print(int(($D1+(65.90-$S2_SS))*1000))")
T1=$(python3 -c "print(int(($D1+(66.90-$S2_SS))*1000))")
TGO=$(python3 -c "print(int($GO_AT*1000))")
TREST=$(python3 -c "print(int(($D1+$D2+$D3+$D4+$D5+(122.00-$S6_SS))*1000))")
TGJ=$(python3 -c "print(int(($D1+$D2+$D3+$D4+$D5+$D6+0.25)*1000))")
TFIN=$(python3 -c "print(int(($D1+$D2+$D3+$D4+$D5+$D6+$D7+0.35)*1000))")

# music: quiet riff under the countdown, hard cut to the drop ON the GO frame
MA_DUR=$GO_AT
MB_DUR=$(python3 -c "print(round($VID-$GO_AT,3))")
MB_END=$(python3 -c "print(round(16.0+$MB_DUR,3))")
FADE_ST=$(python3 -c "print(round($VID-1.6,2))")
TGO_VO=$(python3 -c "print(int($TGO-60))")  # the yell's transient leads the drop by a hair

# duck the loud bed under the later voice cues ([mb]-local time = video - GO_AT)
DUCK=$(python3 -c "
go=$GO_AT
for t in ($TREST/1000, $TGJ/1000, $TFIN/1000):
    a=round(t-go-0.12,2); b=round(t-go+0.95,2)
    print(f'between(t,{a},{b})', end='+')
print('0')")

ffmpeg -nostdin -loglevel error -i "$S/video_noaudio.mp4" -i "$MUSIC" \
  -i "$VOICE/countdown_3.mp3" -i "$VOICE/countdown_2.mp3" -i "$VOICE/countdown_1.mp3" \
  -i "$VOICE/countdown_go.mp3" -i "$VOICE/rest.mp3" -i "$VOICE/good_job.mp3" -i "$VOICE/thats_it.mp3" \
  -filter_complex "\
[1:a]atrim=1.0:$(python3 -c "print(1.0+$MA_DUR)"),asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.4,volume=0.42[ma];\
[1:a]atrim=16.0:$MB_END,asetpts=PTS-STARTPTS,volume=0.95,volume='if($DUCK,0.55,1)':eval=frame,adelay=${TGO}|${TGO}[mb];\
[2:a]adelay=${T3}|${T3},volume=1.6[v3];\
[3:a]adelay=${T2}|${T2},volume=1.6[v2];\
[4:a]adelay=${T1}|${T1},volume=1.6[v1];\
[5:a]adelay=${TGO_VO}|${TGO_VO},volume=1.8[vgo];\
[6:a]adelay=${TREST}|${TREST},volume=1.6[vrest];\
[7:a]adelay=${TGJ}|${TGJ},volume=1.6[vgj];\
[8:a]adelay=${TFIN}|${TFIN},volume=1.6[vfin];\
[ma][mb][v3][v2][v1][vgo][vrest][vgj][vfin]amix=inputs=9:duration=longest:normalize=0,\
atrim=0:$VID,afade=t=out:st=$FADE_ST:d=1.6,alimiter=limit=0.97[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -shortest "$PV/out/promo.mp4" -y

# poster: the GO slam frame
ffmpeg -nostdin -loglevel error -ss $(python3 -c "print(round($GO_AT+0.45,2))") \
  -i "$PV/out/promo.mp4" -frames:v 1 -q:v 3 "$PV/out/promo-poster.jpg" -y
echo "[done] $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$PV/out/promo.mp4")s -> out/promo.mp4 + promo-poster.jpg"
