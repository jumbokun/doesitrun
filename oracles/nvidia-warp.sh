set -e
source /work/env.sh
cd /work/warp
OUT=$(mktemp -d /tmp/oracle_XXXX)
cd $OUT
timeout 1500 python -m warp.examples.core.example_mesh --device cpu --num-frames 20 --stage-path $OUT/mesh.usd 2>&1 | tee $OUT/log.txt
test -s $OUT/mesh.usd
SZ=$(stat -c %s $OUT/mesh.usd)
echo "usd size $SZ"
test "$SZ" -gt 2000
python -I - "$OUT/mesh.usd" <<'PY'
import sys
from pxr import Usd
st = Usd.Stage.Open(sys.argv[1])
prims = [p for p in st.Traverse()]
print("prims", len(prims))
assert len(prims) >= 2
assert st.GetEndTimeCode() >= 10, st.GetEndTimeCode()
PY
python -I -c "
import warp as wp
wp.config.quiet=True
import numpy as np
@wp.kernel
def k(a: wp.array(dtype=float)):
    i = wp.tid()
    a[i] = float(i) * 2.0
a = wp.zeros(8, dtype=float, device='cpu')
wp.launch(k, dim=8, inputs=[a], device='cpu')
assert np.allclose(a.numpy(), np.arange(8)*2.0)
print('kernel ok')
"
echo "ORACLE PASS"
