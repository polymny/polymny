# appliquer le traitement de background-matting sur le dossier des frames en entree
# 

# arguments : 
# - path vers le dossier des frames
# - path vers le background sans la personne
# - path vers le slide (target d'incrustation)
# - position de l'incrustation en pixels (WebcamPosition)
# - taille de l'incrustation en pixels (WebcamSize)
frames=$1
frames_back=$2
slide=$3
position_in_pixels=$4
size_in_pixels=$5

# path vers les algos de background-matting
segmentation='/home/pample/Bureau/Stage_Keying/Background-Matting/Background-Matting/test_segmentation_deeplab.py'
back_matting='/home/pample/Bureau/Stage_Keying/Background-Matting/Background-Matting/test_background-matting_image.py'
incruster='/home/pample/Bureau/Stage_Keying/polymny/scripts/incruster.py'

# activation de l'environnement conda pour background-matting
source ~/anaconda3/etc/profile.d/conda.sh
conda activate back-matting

if [ -e "${frames}/done.txt" ]
then
    # incruster
    python ${incruster} ${frames} ${slide} ${position_in_pixels} ${size_in_pixels}
else
    # segmentation des frames
    python ${segmentation} -i ${frames}

    # extraction de la personne (foreground + mask alpha)
    python ${back_matting} -m real-fixed-cam -m syn-comp-adobe-trainset-15 -i ${frames} -o ${frames} -b ${frames_back}

    echo "segmentation and matting : done" > "${frames}/done.txt"

    # incruster
    python ${incruster} ${frames} ${slide} ${position_in_pixels} ${size_in_pixels}
fi