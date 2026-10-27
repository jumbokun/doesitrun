set -e
source /work/env.sh
cd /work/vggt
OUT=$(mktemp -d /tmp/oracle_XXXX)
cat > $OUT/run.py <<'PY'
import sys, glob, torch, numpy as np
sys.path.insert(0, "/work/vggt")
from vggt.models.vggt import VGGT
from vggt.utils.load_fn import load_and_preprocess_images
from vggt.utils.pose_enc import pose_encoding_to_extri_intri
from vggt.utils.geometry import unproject_depth_map_to_point_map
files = sorted(glob.glob("/work/vggt/examples/kitchen/images/*.png"))[:4]
assert len(files) == 4
model = VGGT.from_pretrained("facebook/VGGT-1B").to("cpu").eval()
images = load_and_preprocess_images(files)
print("images", tuple(images.shape))
with torch.no_grad():
    p = model(images)
S = len(files)
pe = p["pose_enc"]; depth = p["depth"]
assert pe.shape[:2] == (1, S) and pe.shape[-1] == 9, pe.shape
assert depth.shape[:2] == (1, S), depth.shape
assert p["world_points"].shape[-1] == 3
ext, intr = pose_encoding_to_extri_intri(pe, images.shape[-2:])
pts = unproject_depth_map_to_point_map(depth.squeeze(0).numpy(), ext.squeeze(0).numpy(), intr.squeeze(0).numpy())
assert np.isfinite(pts).all() and np.isfinite(depth.numpy()).all()
assert depth.std() > 0 and (depth > 0).float().mean() > 0.5
assert np.isfinite(ext.numpy()).all()
np.savez(sys.argv[1], depth=depth.numpy(), pts=pts)
print("RESULT_OK", tuple(depth.shape), tuple(pts.shape))
PY
timeout 5400 python $OUT/run.py $OUT/out.npz 2>&1 | tee $OUT/log.txt
grep -q RESULT_OK $OUT/log.txt
test $(stat -c %s $OUT/out.npz) -gt 100000
echo ORACLE PASS
