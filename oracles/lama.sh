# Pass: README Inference (`bin/predict.py model.path=$(pwd)/big-lama indir=... outdir=...`, TORCH_HOME/PYTHONPATH as the
# README sets them) inpaints an oracle-generated image+mask pair: same size, the masked object is removed, the rest kept.
# (LaMa_test_images.zip referenced by the README is not in the repo, so the oracle brings its own input.)
# v2:
#  - no `device=cuda` override and no CUDA requirement: bin/predict.py:44 hard-codes `device = torch.device("cpu")`
#    (upstream commit 3bfa8c2, 2023-08-02, "CPU seems quick enough") and ignores the config's device key, so the README
#    path runs on CPU by design. Demanding CUDA made the agent patch bin/predict.py.
#  - checks the inpainting itself, not only the output size.
set -e
source /work/env.sh
cd /work/lama
export TORCH_HOME=$(pwd) PYTHONPATH=$(pwd)
IN=$(mktemp -d); OUT=$(mktemp -d)
python - "$IN" <<'PY'
import sys, numpy as np
from PIL import Image
d = sys.argv[1]
y, x = np.mgrid[0:256, 0:384]
g = (90 + 60 * x / 383 + 30 * y / 255).astype(np.uint8)          # smooth grey background
img = np.stack([g, g, (g.astype(int) + 20).clip(0, 255).astype(np.uint8)], -1)
img[100:156, 160:240] = (255, 0, 255)                            # a magenta block to remove
Image.fromarray(img).save(f"{d}/probe.png")
m = np.zeros((256, 384), np.uint8); m[92:164, 152:248] = 255     # mask covers the block with a margin
Image.fromarray(m).save(f"{d}/probe_mask001.png")               # README: [images_name]_maskXXX[image_suffix]
PY
timeout 2400 python3 bin/predict.py model.path=$(pwd)/big-lama indir=$IN outdir=$OUT
ls -la $OUT
# bin/predict.py:69-72: output is named after the mask file
test -s $OUT/probe_mask001.png || { echo "ORACLE: no inpainted PNG"; exit 1; }
python - "$IN" "$OUT/probe_mask001.png" <<'PY'
import sys, numpy as np
from PIL import Image
src = np.asarray(Image.open(f"{sys.argv[1]}/probe.png").convert("RGB")).astype(int)
out = np.asarray(Image.open(sys.argv[2]).convert("RGB")).astype(int)
print("ORACLE: out shape", out.shape)
assert out.shape == src.shape, out.shape
mask = np.zeros(src.shape[:2], bool); mask[92:164, 152:248] = True
inside = np.abs(out[100:156, 160:240] - src[100:156, 160:240]).mean()
outside = np.abs(out[~mask] - src[~mask]).mean()
mag = ((out[100:156, 160:240, 0] > 200) & (out[100:156, 160:240, 1] < 60)).mean()
print(f"ORACLE: mean|diff| inside={inside:.1f} outside={outside:.2f} magenta share left={mag:.3f}")
assert outside < 3, outside            # unmasked pixels are kept (out_key 'inpainted' blends with the input)
assert inside > 40 and mag < 0.05, (inside, mag)   # the block is gone
PY
echo "ORACLE PASS"
