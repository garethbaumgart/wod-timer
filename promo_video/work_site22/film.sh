#!/usr/bin/env bash
# Portfolio-card silent film from 1080x2340 frames: 2.0 s hold, 0.45 s crossfade, slow 4% zoom. Same recipe as mentalmetal-site/tools/promo-slideshow.py, ffmpeg only.
set -e
out=$1; shift; frames=("$@"); n=${#frames[@]}; hold=2.0; fade=0.45; fps=30; per=$(python3 -c "print(int(($hold+$fade)*$fps))")
args=(ffmpeg -loglevel error -y)
for f in "${frames[@]}"; do args+=(-loop 1 -framerate $fps -t $(python3 -c "print(f'{$hold+$fade:.2f}')") -i "$f"); done
fc=""; for ((i=0;i<n;i++)); do fc+="[$i:v]scale=2160:4680,zoompan=z='1+0.04*on/$per':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x2340:fps=$fps,format=yuv420p[z$i];"; done
prev="[z0]"; off=$hold
for ((i=1;i<n;i++)); do if ((i<n-1)); then o="[v$i]"; else o="[vout]"; fi; fc+="$prev[z$i]xfade=transition=fade:duration=$fade:offset=$(python3 -c "print(f'{$off:.2f}')")$o;"; prev=$o; off=$(python3 -c "print($off+$hold)"); done
fc=${fc%;}
"${args[@]}" -filter_complex "$fc" -map "[vout]" -r $fps -c:v libx264 -pix_fmt yuv420p -profile:v main -crf 22 -movflags +faststart -an "$out"
ffprobe -v error -show_entries stream=width,height,duration -of csv=p=0 "$out"
