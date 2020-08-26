# extraire une video en frames
#

# argument : la video
video_name=$(echo "$1" | cut -f 1 -d '.')

# creer un dossier pour contenir les frames
outdir="${video_name}_input"
mkdir $outdir

# extraction des frames a 25 FPS
ffmpeg -i $1 -r 25 "${outdir}/%04d_img.png" -hide_banner