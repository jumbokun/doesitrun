set -e
source /work/env.sh
cd /work/SPADE
test -d checkpoints/coco_pretrained
OUT=$(mktemp -d /tmp/spade_out.XXXX)
timeout 3000 python test.py --name coco_pretrained --dataset_mode coco --dataroot datasets/coco_stuff --gpu_ids -1 --how_many 2 --results_dir $OUT --batchSize 1
N=$(find $OUT -path '*images*' \( -name '*.png' -o -name '*.jpg' \) | wc -l)
echo "images: $N"
test "$N" -ge 2
python - "$OUT" <<'P'
import sys,glob
from PIL import Image
fs=[f for f in glob.glob(sys.argv[1]+'/**/*',recursive=True) if 'images' in f and f.endswith(('.png','.jpg'))]
import os
syn=[f for f in fs if 'synthesized' in f]
assert syn, fs
for f in syn:
    im=Image.open(f); assert im.size[0]>=256 and os.path.getsize(f)>10000,(f,im.size)
    ex=im.convert('L').getextrema(); assert ex[1]-ex[0]>30,f
print("ok",len(syn))
P
echo ORACLE PASS
