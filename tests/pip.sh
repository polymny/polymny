PIP1="pip1.mp4"
PIP2="pip2.mp4"
PIP3="pip3.mp4"
FINAL="final.mp4"
LOGLEVEL='panic'

rm $PIP1
rm $PIP2
rm $PIP5
rm $FINAL


ffmpeg -y -hide_banner -loglevel $LOGLEVEL -stats \
-i slide0.png -i record0.webm \
-filter_complex \
"[1]scale=300:-1 [pip]; \
[0][pip] overlay=4:main_h-overlay_h-4" \
-profile:v main \
-level 3.1 -b:v 440k -ar 44100 -ab 128k \
-vcodec h264 -acodec mp3 \
$PIP1

ffmpeg -y -hide_banner -loglevel $LOGLEVEL -stats \
-i slide1.png -i record1.webm \
-filter_complex \
"[1]scale=300:-1 [pip]; \
[0][pip] overlay=main_w-overlay
_w-10:main_h-overlay_h-10" \
-profile:v main \
-level 3.1 -b:v 440k -ar 44100 -ab 128k \
-vcodec h264 -acodec mp3 \
$PIP2

ffmpeg -y -hide_banner -loglevel $LOGLEVEL -stats \
-i slide2.png -i record2.webm \
-filter_complex \
"[1]scale=300:-1 [pip]; \
[0][pip] overlay=main_w-overlay
_w-10:main_h-overlay_h-10" \
-profile:v main \
-level 3.1 -b:v 440k -ar 44100 -ab 128k \
-vcodec h264 -acodec mp3 \
$PIP3

ffmpeg -y -hide_banner -loglevel $LOGLEVEL -stats \
-f concat -safe 0 -i pipList.txt -c copy $FINAL
