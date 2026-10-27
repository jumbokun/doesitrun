set -e
source /work/env.sh
cd /work/stylegan3
OUT=$(mktemp -d /tmp/sg3out.XXXXXX)
timeout 3000 python gen_images.py --outdir="$OUT" --trunc=1 --seeds=2,3 \
  --network=https://api.ngc.nvidia.com/v2/models/nvidia/research/stylegan3/versions/1/files/stylegan3-r-afhqv2-512x512.pkl
ls -l "$OUT"
python - "$OUT" <<'P'
import sys, glob, numpy as np
from PIL import Image
fs = sorted(glob.glob(sys.argv[1] + '/*.png'))
assert len(fs) == 2, fs
for f in fs:
    im = Image.open(f).convert('RGB')
    assert im.size == (512, 512), im.size
    a = np.asarray(im).astype(float)
    assert a.std() > 20, a.std()
print('images ok', fs)
P
echo ORACLE PASS
