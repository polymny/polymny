#!/usr/bin/env bash
# appliquer le traitement de background-matting sur le dossier des frames en entree
#

# arguments :
# - path vers la vidéo
# - path vers le dossier des frames
# - path vers le background sans la personne
# - path vers le slide (target d'incrustation)
# - position de l'incrustation en pixels (WebcamPosition)
# - taille de l'incrustation en pixels (WebcamSize)
# - path vers la sortie (pip)
video_name=$1
frames_back=$2
slide=$3
position_in_pixels=$4
size_in_pixels=$5
pip_out=$6

# path vers les algos de background-matting
segmentation='../../Background-Matting/test_segmentation_deeplab.py'
back_matting='../../Background-Matting/test_background-matting_image.py'
incruster='../scripts/incruster.py'

conda-init () {
    __conda_setup="$('$HOME/.anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]
    then
        eval "$__conda_setup"
    else
        if [ -f "$HOME/.anaconda3/etc/profile.d/conda.sh" ]
        then
            . "$HOME/.anaconda3/etc/profile.d/conda.sh"
        else
            export PATH="$HOME/.anaconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
}

# activation de l'environnement conda pour background-matting
conda-init
conda activate back-matting

export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=0

# Extraction des frames de la video
frames="${video_name}_input"
mkdir $frames
ffmpeg -i $1 -r 25 "${frames}/%04d_img.png" -hide_banner

if [ -e "${frames}/done.txt" ]
then
    # incruster
    python ${incruster} ${frames} ${slide} ${position_in_pixels} ${size_in_pixels}
else
    # segmentation des frames
    python ${segmentation} -i ${frames}

    # extraction de la personne (foreground + mask alpha)
    python ${back_matting} -m real-fixed-cam -m syn-comp-adobe-trainset-15 -i ${frames} -o ${frames} -b ${frames_back} -tb ${frames_back}
    # python ${back_matting} -m real-fixed-cam -m syn-comp-adobe-trainset-15 -i ${frames} -o ${frames} -b ${frames_back}

    echo "segmentation and matting : done" > "${frames}/done.txt"

    # incruster
    python ${incruster} ${frames} ${slide} ${position_in_pixels} ${size_in_pixels}
fi

# creer la video
ffmpeg -y -r 25 -f image2 -start_number 0 -i "${frames}/%d_comp.png" -vcodec libx264 -crf 15 -s 1920x1080 -pix_fmt yuv420p ${pip_out}
