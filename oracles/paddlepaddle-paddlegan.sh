set -e
source /work/env.sh
cd /work/PaddleGAN
OUT=$(mktemp -d /tmp/oracle_anime.XXXXXX)
# docs/en_US/tutorials/animegan.md:23 — python applications/tools/animeganv2.py --input_image ${PATH_OF_IMAGE}
# --cpu is a documented flag of the tool (applications/tools/animeganv2.py:41-44).
timeout 1800 python applications/tools/animeganv2.py --input_image docs/imgs/animeganv2_test.jpg --output_path "$OUT" --cpu
echo "files:"; find "$OUT" -type f
timeout 120 python - "$OUT" <<'P'
import sys, os
import numpy as np
from PIL import Image
# ppgan/apps/animegan_predictor.py:88-89 writes <output_path>/anime.png, resized back to the input size (:79-81)
f = os.path.join(sys.argv[1], "anime.png")
assert os.path.isfile(f), "no anime.png"
assert os.path.getsize(f) > 5000, "too small"
o = Image.open(f).convert("RGB")
i = Image.open("docs/imgs/animeganv2_test.jpg").convert("RGB")
assert o.size == i.size, (o.size, i.size)
a = np.asarray(o).astype(float)
assert a.std() > 10, "degenerate image"
assert np.abs(a - np.asarray(i).astype(float)).mean() > 3, "output identical to input"
# v1 stopped here, so any image that differs from the input passed (e.g. an untrained generator).
# The repo ships the expected Hayao result for this exact photo: docs/imgs/animeganv2_res.jpg (1280x832,
# shown in docs/en_US/tutorials/animegan.md). A working model must land much closer to it than the input
# photo does (input vs reference ~35 mean abs diff; the probe run's output was ~10).
r = Image.open("docs/imgs/animeganv2_res.jpg").convert("RGB")
rr = np.asarray(r).astype(float)
d_out = np.abs(np.asarray(o.resize(r.size, Image.BILINEAR)).astype(float) - rr).mean()
d_in = np.abs(np.asarray(i.resize(r.size, Image.BILINEAR)).astype(float) - rr).mean()
print("out-vs-ref %.1f  in-vs-ref %.1f" % (d_out, d_in))
assert d_out < 0.6 * d_in, "output does not resemble the reference AnimeGANv2 result"
print("ok", f, o.size)
P
echo "ORACLE PASS"
