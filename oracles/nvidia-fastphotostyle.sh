set -e
source /work/env.sh
cd /work/FastPhotoStyle
O=$(mktemp -d /tmp/oracle.XXXXXX)
python - "$O" <<'PY'
import sys, numpy as np
from PIL import Image
o = sys.argv[1]
rng = np.random.RandomState(0)
def mk(w, h, f):
    y, x = np.mgrid[0:h, 0:w]
    return Image.fromarray(f(x / w, y / h).clip(0, 255).astype(np.uint8))
c = mk(240, 160, lambda x, y: np.stack([60 + 100 * x, 120 + 80 * (y > .5) * 1.0 + 20 * y, 200 - 150 * y], -1))
s = mk(200, 140, lambda x, y: np.stack([230 - 120 * y, 140 + 60 * x, 40 + 100 * x * y], -1) + rng.randint(0, 25, (140, 200, 3)))
c.save(o + "/content.png"); s.save(o + "/style.png")
PY
timeout 3000 python demo.py --cuda 0 --fast --no_post --content_image_path $O/content.png --style_image_path $O/style.png --output_image_path $O/out.png 2>&1 | tee $O/log.txt
python - "$O" <<'PY'
import sys, numpy as np
from PIL import Image
o = sys.argv[1]
out = Image.open(o + "/out.png").convert("RGB")
c = Image.open(o + "/content.png")
assert out.size == c.size, (out.size, c.size)
a = np.asarray(out).astype(float); b = np.asarray(c.convert("RGB")).astype(float)
assert a.std() > 5, "output looks blank"
assert np.abs(a - b).mean() > 3, "output identical to content"
assert not np.isnan(a).any()
print("ok", out.size, a.mean(), a.std())
PY
echo ORACLE PASS
