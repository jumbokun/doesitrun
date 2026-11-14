set -e
source /work/env.sh
cd /work/Depth-Anything-3
OUT=$(mktemp -d /tmp/da3_oracle.XXXXXX)
# The export dir must NOT exist yet: InputHandler.handle_export_dir asks "Do you want to clean it
# and continue?" for an existing dir and aborts without a tty (src/depth_anything_3/services/input_handlers.py:41-60).
EXP="$OUT/export"
# --device cpu is a documented CLI option (cli.py:119, default "cuda"); no repo patch should be needed for CPU.
# DA3-SMALL is the README's smallest Apache-2.0 model (README.md:224); package lives in src/, so cwd does not shadow it.
timeout 3000 da3 auto assets/examples/SOH \
  --export-format mini_npz-glb \
  --export-dir "$EXP" \
  --model-dir depth-anything/DA3-SMALL \
  --device cpu < /dev/null
# mini_npz writes <export_dir>/exports/mini_npz/results.npz (utils/export/npz.py:58);
# glb writes <export_dir>/scene.glb (utils/export/glb.py:179).
NPZ="$EXP/exports/mini_npz/results.npz"
GLB="$EXP/scene.glb"
test -s "$NPZ" || { echo "no results.npz"; find "$EXP"; exit 1; }
test -s "$GLB" || { echo "no scene.glb"; find "$EXP"; exit 1; }
[ "$(stat -c %s "$GLB")" -gt 10000 ] || { echo "glb too small"; exit 1; }
python - "$NPZ" "$GLB" <<'P'
import sys, numpy as np, trimesh
d = np.load(sys.argv[1])
print({k: d[k].shape for k in d.files})
dep = d["depth"]                      # [N,H,W] (README.md:113), N = 2 images in assets/examples/SOH
assert dep.ndim == 3 and dep.shape[0] == 2, dep.shape
assert min(dep.shape[1:]) > 100 and max(dep.shape[1:]) == 504, dep.shape  # cli.py:124-126 process_res=504, upper_bound_resize
assert np.isfinite(dep).all() and dep.std() > 0
if "conf" in d.files:
    assert d["conf"].shape == dep.shape, d["conf"].shape
if "extrinsics" in d.files:
    # README.md:117 says [N,3,4]; specs.py:40 comments N,4,4 - accept either.
    assert d["extrinsics"].shape in [(2, 3, 4), (2, 4, 4)], d["extrinsics"].shape
if "intrinsics" in d.files:
    assert d["intrinsics"].shape == (2, 3, 3), d["intrinsics"].shape   # README.md:119
s = trimesh.load(sys.argv[2])
geoms = list(s.geometry.values()) if hasattr(s, "geometry") else [s]
npts = sum(len(getattr(g, "vertices", [])) for g in geoms)
print("glb geometries", len(geoms), "vertices", npts)
assert npts > 1000, npts
print("ok")
P
echo "ORACLE PASS"
