rm PIPoutput.mp4
ffmpeg -y -i slide0.png -i record0.webm \
-filter_complex "[1]scale=iw/2:ih/2 [pip]; [0][pip] overlay=main_w-overlay_w-10:main_h-overlay_h-10" -profile:v main -level 3.1 -b:v 440k -ar 44100 -ab 128k -s 720x400 -vcodec h264 -acodec mp3 PIPoutput.mp4
vlc PIPoutput.mp4
