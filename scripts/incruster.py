'''
Incruster les images extraites avec background-matting sur un diapo.

Entrees :
    - path vers le dossier des masks alpha et l'extraction de background-matting
    - path vers le diapo

Sortie :
    - frames des images incrustees sur le diapo
'''
from PIL import Image
import sys
import os

# arguments de la ligne de commande
path = sys.argv[1]                  # path vers les frames
bg = Image.open(sys.argv[2])        # path vers le diapo
position_in_pixels = sys.argv[3]    # position de l'incrustation
size_in_pixels = sys.argv[4]        # taille de l'incrustation

# recuperer les extractions et les masks alpha
fgs = sorted([os.path.join(path, f[:-4]) for f in os.listdir(path) if f.endswith("_fg.png")])
masks = sorted([os.path.join(path, f[:-4]) for f in os.listdir(path) if f.endswith("_out.png")])

# incruster une image sur le diapo en utilisant le mask alpha
# et positionner l'image a l'endroit fourni
def incruster(fg, mask, bg, position, size):
    ret = bg.copy()
    fg = fg.resize(size)
    mask = mask.resize(size)
    ret.paste(fg, position, mask)
    return ret

# taille de l'incrustation
w, h = Image.open(fgs[0]+'.png').size
w_new = int(size_in_pixels)
h = int(h * w_new / w)
w = w_new

# position de l'incrustation
W, H = bg.size
if position_in_pixels == "4:4":
    position = (4,4)

if position_in_pixels == "W-w-4:4":
    position = (W-w-4,4)

if position_in_pixels == "4:H-h-4":
    position = (4,H-h-4)

if position_in_pixels == "W-w-4:H-h-4":
    position = (W-w-4,H-h-4)

# lire les images et les incruster
for i in range(len(fgs)):
    fg = Image.open(fgs[i]+'.png')
    mask = Image.open(masks[i]+'.png')
    ret = incruster(fg, mask, bg, position, (w,h))
    ret.save(path+'/'+str(i)+'_comp.png', quality=95)
