# reconstruire une video a partir des frames de l'incrustation
#

# arguments : 
# - path vers les frames de l'incrustation
# - path vers la sortie (pip)
frames=$1
pip_out=$2

# creer la video
ffmpeg -y -r 25 -f image2 -start_number 0 -i "${frames}/%d_comp.png" -vcodec libx264 -crf 15 -s 1920x1080 -pix_fmt yuv420p ${pip_out}
