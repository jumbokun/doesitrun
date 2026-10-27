set -e
source /work/env.sh
cd /work/PaddleGAN
OUT=$(mktemp -d /tmp/oracle_anime.XXXXXX)
timeout 1800 python applications/tools/animeganv2.py --input_image docs/imgs/animeganv2_test.jpg --output_path "$OUT" --cpu
echo "files:"; find "$OUT" -type f
timeout 120 python - "$OUT" <<'P'
import sys, glob, os
import numpy as np
from PIL import Image
fs=[f for f in glob.glob(sys.argv[1]+'/**/*',recursive=True) if f.lower().endswith(('.png','.jpg','.jpeg'))]
assert fs, "no output image"
f=fs[0]
assert os.path.getsize(f)>5000, "too small"
o=Image.open(f).convert('RGB'); i=Image.open('docs/imgs/animeganv2_test.jpg').convert('RGB')
a=np.asarray(o).astype(float)
assert min(o.size)>=64 and a.std()>10, "degenerate image"
b=np.asarray(i.resize(o.size)).astype(float)
assert np.abs(a-b).mean()>3, "output identical to input"
print("ok",f,o.size)
P
echo "ORACLE PASS"
