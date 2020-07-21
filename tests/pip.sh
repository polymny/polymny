PIP1="tmp/pip1.mp4"
PIP2="tmp/pip2.mp4"
PIP3="tmp/pip3.mp4"
FINAL="tmp/final.mp4"
LOGLEVEL='warning'

rm $PIP1
rm $PIP2
rm $PIP5
rm $FINAL


ffmpeg -y -hide_banner -loglevel $LOGLEVEL -stats \
-i tmp/slide0.png -i tmp/record0.webm \
-filter_complex \
"[0] scale=1920:1080 [slide]; \
[1]scale=300:-1 [pip]; \
[slide][pip] overlay=4:main_h-overlay_h-4" \
-profile:v main \
-level 3.1 -b:v 440k -ar 44100 -ab 128k \
-vcodec h264 -acodec mp3 \
$PIP1

ffmpeg -y -hide_banner -loglevel $LOGLEVEL -stats \
-i tmp/slide1.png -i tmp/record1.webm \
-filter_complex \
"[1]scale=300:-1 [pip]; \
[0][pip] overlay=main_w-overlay
_w-10:main_h-overlay_h-10" \
-profile:v main \
-level 3.1 -b:v 440k -ar 44100 -ab 128k \
-vcodec h264 -acodec mp3 \
$PIP2

ffmpeg -y -hide_banner -loglevel $LOGLEVEL -stats \
-i tmp/slide2.png -i tmp/record2.webm \
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
