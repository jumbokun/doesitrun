set -e
source /work/env.sh
cd /work/Depth-Anything-3
OUT=$(mktemp -d /tmp/da3_oracle.XXXXXX)
CUDA_VISIBLE_DEVICES="" timeout 3000 da3 auto assets/examples/SOH \
  --export-format mini_npz-glb \
  --export-dir "$OUT" \
  --model-dir depth-anything/DA3-SMALL
NPZ=$(find "$OUT" -name results.npz | head -n1)
GLB=$(find "$OUT" -name '*.glb' | head -n1)
[ -n "$NPZ" ] || { echo "no npz"; exit 1; }
[ -n "$GLB" ] || { echo "no glb"; exit 1; }
[ "$(stat -c %s "$GLB")" -gt 10000 ] || { echo "glb too small"; exit 1; }
python - "$NPZ" <<'P'
import sys, numpy as np
d = np.load(sys.argv[1])
print({k: d[k].shape for k in d.files})
dep = d["depth"]
assert dep.ndim == 3 and dep.shape[0] == 2, dep.shape
assert dep.shape[1] > 100 and dep.shape[2] > 100
assert np.isfinite(dep).all() and dep.std() > 0
P
echo "ORACLE PASS"
