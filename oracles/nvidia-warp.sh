set -e
set -o pipefail
source /work/env.sh
OUT=$(mktemp -d /tmp/oracle_XXXX)
# Run from a fresh dir: /work/warp/warp is the uncompiled source package and would shadow an installed
# warp-lang under `python -m` (cwd is on sys.path).
cd $OUT
# README "Running Examples": python -m warp.examples.<subdir>.<example>; flags from
# warp/examples/core/example_mesh.py:149-156.
timeout 1500 python -m warp.examples.core.example_mesh --device cpu --num-frames 20 --stage-path $OUT/mesh.usd 2>&1 | tee $OUT/log.txt
test -s $OUT/mesh.usd
python -I - "$OUT/mesh.usd" <<'PY'
import sys
from pxr import Usd, UsdGeom
st = Usd.Stage.Open(sys.argv[1])
prims = list(st.Traverse())
print("prims", len(prims), "end", st.GetEndTimeCode())
# UsdRenderer.begin_frame sets time code = round(sim_time * 60) (warp/_src/render/render_usd.py:162-169)
assert st.GetEndTimeCode() >= 15, st.GetEndTimeCode()
# render_points writes a PointInstancer whose positions are time-sampled (render_usd.py:972-984)
inst = [UsdGeom.PointInstancer(p) for p in prims if p.IsA(UsdGeom.PointInstancer)]
assert inst, [str(p.GetPath()) for p in prims]
attr = inst[0].GetPositionsAttr()
ts = attr.GetTimeSamples()
assert len(ts) >= 15, ts
first, last = attr.Get(ts[0]), attr.Get(ts[-1])
assert len(first) == 1000 and len(last) == 1000, (len(first), len(last))  # num_particles, example_mesh.py:82
y0 = sum(p[1] for p in first) / len(first)
y1 = sum(p[1] for p in last) / len(last)
print("mean y first/last", y0, y1)
# particles start at y in [15, 25] and fall under gravity (simulate kernel); ~0.5 units over 20 frames
assert y1 < y0 - 0.2, (y0, y1)
assert any(p.IsA(UsdGeom.Mesh) for p in prims), "bunny mesh missing"
PY
# Warp reads kernel source through inspect, so kernels cannot be defined in `python -c`; use a file.
cat > $OUT/kern.py <<'PY'
import numpy as np
import warp as wp
wp.config.quiet = True

@wp.kernel
def k(a: wp.array(dtype=float)):
    i = wp.tid()
    a[i] = float(i) * 2.0

a = wp.zeros(8, dtype=float, device="cpu")
wp.launch(k, dim=8, inputs=[a], device="cpu")
assert np.allclose(a.numpy(), np.arange(8) * 2.0), a.numpy()
print("kernel ok")
PY
python -I $OUT/kern.py | tee $OUT/kern.txt
grep -q "kernel ok" $OUT/kern.txt
echo "ORACLE PASS"
