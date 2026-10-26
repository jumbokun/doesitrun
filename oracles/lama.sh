# Pass: README predict.py with big-lama inpaints an oracle-generated image+mask pair on CUDA.
# (LaMa_test_images.zip referenced by the README is not in the repo, so the oracle brings its own input.)
set -e
source /work/env.sh
cd /work/lama
export TORCH_HOME=$(pwd) PYTHONPATH=$(pwd)
rm -rf /tmp/oracle_lama_in /tmp/oracle_lama && mkdir -p /tmp/oracle_lama_in
python - <<'PY'
import numpy as np
from PIL import Image
y, x = np.mgrid[0:256, 0:384]
img = np.stack([(x * 255 // 383), (y * 255 // 255), ((x + y) % 64) * 4], -1).astype(np.uint8)
Image.fromarray(img).save("/tmp/oracle_lama_in/probe.png")
m = np.zeros((256, 384), np.uint8); m[96:160, 150:250] = 255
Image.fromarray(m).save("/tmp/oracle_lama_in/probe_mask001.png")
PY
timeout 2400 python3 bin/predict.py model.path=$(pwd)/big-lama indir=/tmp/oracle_lama_in outdir=/tmp/oracle_lama device=cuda
ls -la /tmp/oracle_lama
out=$(ls /tmp/oracle_lama/*.png | head -1); test -n "$out"
python - "$out" <<'PY'
import sys, numpy as np
from PIL import Image
a = np.asarray(Image.open(sys.argv[1]).convert("RGB")); print("ORACLE: out shape", a.shape)
assert a.shape[:2] == (256, 384)
PY
echo "ORACLE PASS"
