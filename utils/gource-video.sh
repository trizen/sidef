#!/bin/sh

outfile="sidef.mp4"
resolution="1920x1080"
fps=30
speed=0.03
timescale=0.6

time gource . \
    -s $speed \
    -c $timescale \
    -$resolution \
    --title "Sidef" \
    --background-colour 121212 \
    --dir-colour eeeeee \
    --filename-colour cccccc \
    --highlight-colour ffffff \
    --font-size 25 \
    --user-font-size 18 \
    --key \
    --date-format "%d/%m/%Y" \
    --auto-skip-seconds 0.001 \
    --multi-sampling  \
    --highlight-users \
    --max-files 0 \
    --stop-at-end \
    --output-framerate $fps \
    --hide mouse,progress \
    --output-ppm-stream - \
    | ffmpeg -y -r $fps -f image2pipe -vcodec ppm -i - -vcodec libx264 -preset medium -crf 20 -threads 2 $outfile
