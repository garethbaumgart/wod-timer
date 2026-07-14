#!/bin/bash
# The Wharf WOD Timer portrait promo v3 (1290x2796, ~34s).
# 2026-07-14 rework for 1.1.0: the coach counts you in on the NEW giant
# orange bare digits, GO floods the screen green as the rock drops, then
# tap-to-count rounds, the Tabata colour flip, the tablet wall-clock, the
# watch, and a real FINISH celebration. Hard cuts; every voice cue lands
# frame-accurate. Wharfie rides the caption pills (mktext.py).
set -euo pipefail
PV="$(cd "$(dirname "$0")" && pwd)"
APP="$(cd "$PV/.." && pwd)"
MUSIC="$PV/music/motivation_epic_rock_alexgrohl.mp3"
VOICE="$APP/assets/audio/major"
BEEP="$APP/assets/audio/major/beep.m4a"
W3="$PV/work3"
RAWP="$W3/raw_phone.mov"
RAWT="$W3/raw_tablet_android.mp4"
RAWW="$W3/raw_watch.mov"
RAWK="$W3/raw_pickup.mov"
TXT="$PV/work/txt"
S="$W3/scenes"; rm -rf "$S"; mkdir -p "$S" "$PV/out"
W=1290; H=2796; FPS=30; DARK="0x050510"

norm="setsar=1,format=yuv420p,fps=$FPS"

live_scene(){ # raw ss t capPNG out
  ffmpeg -nostdin -loglevel error -ss "$2" -t "$3" -i "$1" -i "$4" \
    -filter_complex "[0:v]scale=$W:$H:flags=lanczos,setsar=1[b];[b][1:v]overlay=0:0:format=auto:eof_action=repeat,$norm[v]" \
    -map "[v]" -c:v libx264 -crf 16 -preset veryfast -an "$5" -y
}

# ---- locked cut table (frame-hunted from the raws) ------------------------
D1=1.8                    # s1 title
S2_SS=81.90; D2=3.57      # s2 countdown: digit flips at 82.45/83.45/84.45
S3_SS=85.47; D3=2.53      # s3 GO -> WORK flood (flip at 85.47)
S4_SS=88.00; D4=4.30      # s4 rounds: ROUNDS ticks at 88.30/89.60/90.90
S5_SS=144.00; D5=5.30     # s5 tabata: WORK->REST flip at 146.95
TABLET_SS=${TABLET_SS:-0}; D6=4.2   # s6 tablet (set via env after mark check)
WATCH_SS=16.30; D7=4.2    # s7 watch
S8_SS=100.83; D8=3.40     # s8 finished (pickup; Finished! flip at 101.93)
D9=3.75                   # s9 end card

[ "$TABLET_SS" != "0" ] || { echo "set TABLET_SS=<seconds>"; exit 2; }

echo "[s1] title"; ffmpeg -nostdin -loglevel error \
  -f lavfi -t $D1 -i "color=c=$DARK:s=${W}x${H}:r=$FPS" \
  -loop 1 -t $D1 -i "$TXT/title_overlay.png" \
  -filter_complex "[1:v]format=rgba,fade=t=in:st=0.1:d=0.45:alpha=1[tx];[0:v][tx]overlay=0:0:format=auto[c];[c]fade=t=in:st=0:d=0.25,$norm[v]" \
  -map "[v]" -c:v libx264 -crf 16 -preset veryfast -an "$S/s1.mp4" -y

echo "[s2] countdown"; ffmpeg -nostdin -loglevel error -ss $S2_SS -t $D2 -i "$RAWP" \
  -filter_complex "[0:v]scale=$W:$H:flags=lanczos,$norm[v]" \
  -map "[v]" -c:v libx264 -crf 16 -preset veryfast -an "$S/s2.mp4" -y

echo "[s3] GO"; ffmpeg -nostdin -loglevel error -ss $S3_SS -t $D3 -i "$RAWP" \
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

echo "[s4] rounds"; live_scene "$RAWP" $S4_SS $D4 "$TXT/c_rounds.png" "$S/s4.mp4"
echo "[s5] tabata"; live_scene "$RAWP" $S5_SS $D5 "$TXT/c_tabata.png" "$S/s5.mp4"

echo "[s6] tablet"; ffmpeg -nostdin -loglevel error \
  -f lavfi -t $D6 -i "color=c=$DARK:s=${W}x${H}:r=$FPS" \
  -ss $TABLET_SS -t $D6 -i "$RAWT" \
  -loop 1 -t $D6 -i "$TXT/tablet_mask.png" \
  -loop 1 -t $D6 -i "$TXT/h_tablet.png" -loop 1 -t $D6 -i "$TXT/c_tablet.png" \
  -filter_complex "\
[1:v]scale=1230:769:flags=lanczos,format=rgba[tf];\
[2:v]format=gray[m];[tf][m]alphamerge[tm];\
[0:v][tm]overlay=30:930:format=auto[c1];\
[3:v]format=rgba,fade=t=in:st=0.15:d=0.3:alpha=1[hd];[c1][hd]overlay=0:0:format=auto[c2];\
[4:v]format=rgba,fade=t=in:st=0.3:d=0.3:alpha=1[cp];[c2][cp]overlay=0:0:format=auto,$norm[v]" \
  -map "[v]" -t $D6 -c:v libx264 -crf 16 -preset veryfast -an "$S/s6.mp4" -y

echo "[s7] watch"; ffmpeg -nostdin -loglevel error \
  -f lavfi -t $D7 -i "color=c=$DARK:s=${W}x${H}:r=$FPS" \
  -ss $WATCH_SS -t $D7 -i "$RAWW" \
  -loop 1 -t $D7 -i "$TXT/watch_mask.png" \
  -loop 1 -t $D7 -i "$TXT/h_watch.png" -loop 1 -t $D7 -i "$TXT/c_watch.png" \
  -filter_complex "\
[1:v]scale=957:1141:flags=lanczos,format=rgba[wf];\
[2:v]format=gray[m];[wf][m]alphamerge[wm];\
[0:v][wm]overlay=166:760:format=auto[c1];\
[3:v]format=rgba,fade=t=in:st=0.15:d=0.3:alpha=1[hd];[c1][hd]overlay=0:0:format=auto[c2];\
[4:v]format=rgba,fade=t=in:st=0.3:d=0.3:alpha=1[cp];[c2][cp]overlay=0:0:format=auto,$norm[v]" \
  -map "[v]" -t $D7 -c:v libx264 -crf 16 -preset veryfast -an "$S/s7.mp4" -y

echo "[s8] finished"; live_scene "$RAWK" $S8_SS $D8 "$TXT/c_done.png" "$S/s8.mp4"

echo "[s9] end"; ffmpeg -nostdin -loglevel error \
  -f lavfi -t $D9 -i "color=c=$DARK:s=${W}x${H}:r=$FPS" \
  -loop 1 -t $D9 -i "$TXT/end_overlay.png" \
  -filter_complex "[1:v]format=rgba,fade=t=in:st=0.05:d=0.3:alpha=1[tx];[0:v][tx]overlay=0:0:format=auto[c];[c]fade=t=out:st=3.3:d=0.45,$norm[v]" \
  -map "[v]" -c:v libx264 -crf 16 -preset veryfast -an "$S/s9.mp4" -y

echo "[+] hard-cut concat"
fc=""; inputs=""
for i in 1 2 3 4 5 6 7 8 9; do inputs+=" -i $S/s$i.mp4"; fc+="[$((i-1)):v]"; done
ffmpeg -nostdin -loglevel error $inputs -filter_complex "${fc}concat=n=9:v=1:a=0[v]" \
  -map "[v]" -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p "$S/video_noaudio.mp4" -y

VID=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$S/video_noaudio.mp4")
echo "[+] audio (video ${VID}s)"

# ---- cue offsets (video seconds -> ms), derived from the cut table --------
GO_AT=$(python3 -c "print(round($D1+$D2,3))")
T3=$(python3 -c "print(int(($D1+(82.45-$S2_SS))*1000))")
T2=$(python3 -c "print(int(($D1+(83.45-$S2_SS))*1000))")
T1=$(python3 -c "print(int(($D1+(84.45-$S2_SS))*1000))")
TGO=$(python3 -c "print(int($GO_AT*1000))")
B4=$(python3 -c "print($D1+$D2+$D3)")
RB1=$(python3 -c "print(int(($B4+(88.30-$S4_SS))*1000))")
RB2=$(python3 -c "print(int(($B4+(89.60-$S4_SS))*1000))")
RB3=$(python3 -c "print(int(($B4+(90.90-$S4_SS))*1000))")
B5=$(python3 -c "print($B4+$D4)")
TREST=$(python3 -c "print(int(($B5+(146.95-$S5_SS))*1000))")
B8=$(python3 -c "print($B5+$D5+$D6+$D7)")
TGJ=$(python3 -c "print(int(($B8+(101.93-$S8_SS)+0.30)*1000))")
B9=$(python3 -c "print($B8+$D8)")
TFIN=$(python3 -c "print(int(($B9+0.40)*1000))")

MA_DUR=$GO_AT
MB_DUR=$(python3 -c "print(round($VID-$GO_AT,3))")
MB_END=$(python3 -c "print(round(16.0+$MB_DUR,3))")
FADE_ST=$(python3 -c "print(round($VID-1.6,2))")
TGO_VO=$(python3 -c "print(int($TGO-60))")

DUCK=$(python3 -c "
go=$GO_AT
for t in ($TREST/1000, $TGJ/1000, $TFIN/1000):
    a=round(t-go-0.12,2); b=round(t-go+0.95,2)
    print(f'between(t,{a},{b})', end='+')
print('0')")

ffmpeg -nostdin -loglevel error -i "$S/video_noaudio.mp4" -i "$MUSIC" \
  -i "$VOICE/countdown_3.mp3" -i "$VOICE/countdown_2.mp3" -i "$VOICE/countdown_1.mp3" \
  -i "$VOICE/countdown_go.mp3" -i "$VOICE/rest.mp3" -i "$VOICE/good_job.mp3" -i "$VOICE/thats_it.mp3" \
  -i "$BEEP" -i "$BEEP" -i "$BEEP" \
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
[9:a]adelay=${RB1}|${RB1},volume=0.9[b1];\
[10:a]adelay=${RB2}|${RB2},volume=0.9[b2];\
[11:a]adelay=${RB3}|${RB3},volume=0.9[b3];\
[ma][mb][v3][v2][v1][vgo][vrest][vgj][vfin][b1][b2][b3]amix=inputs=12:duration=longest:normalize=0,\
atrim=0:$VID,afade=t=out:st=$FADE_ST:d=1.6,alimiter=limit=0.97[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -shortest "$PV/out/promo.mp4" -y

ffmpeg -nostdin -loglevel error -ss $(python3 -c "print(round($GO_AT+0.45,2))") \
  -i "$PV/out/promo.mp4" -frames:v 1 -q:v 3 "$PV/out/promo-poster.jpg" -y
echo "[done] $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$PV/out/promo.mp4")s -> out/promo.mp4 + promo-poster.jpg"
