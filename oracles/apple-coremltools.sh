set -e
source /work/env.sh
cd /work/coremltools
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'PY'
import sys, os
import numpy as np, torch, torch.nn as nn
import coremltools as ct
out = sys.argv[1]
torch.manual_seed(0)
class Net(nn.Module):
    def __init__(s):
        super().__init__()
        s.c = nn.Conv2d(3, 8, 3, padding=1); s.r = nn.ReLU()
        s.p = nn.AdaptiveAvgPool2d(1); s.f = nn.Linear(8, 5)
    def forward(s, x):
        return s.f(s.p(s.r(s.c(x))).flatten(1))
m = Net().eval()
ex = torch.rand(1, 3, 32, 32)
tr = torch.jit.trace(m, ex)
ml = ct.convert(tr, inputs=[ct.TensorType(name="x", shape=ex.shape)],
                convert_to="mlprogram", compute_units=ct.ComputeUnit.CPU_ONLY)
p = os.path.join(out, "net.mlpackage")
ml.save(p)
assert os.path.isdir(p)
size = sum(os.path.getsize(os.path.join(d, f)) for d, _, fs in os.walk(p) for f in fs)
assert size > 1000, size
spec = ct.models.MLModel(p, skip_model_load=True).get_spec()
assert spec.WhichOneof("Type") == "mlProgram", spec.WhichOneof("Type")
assert [i.name for i in spec.description.input] == ["x"]
assert len(spec.description.output) == 1
ops = {op.type for f in spec.mlProgram.functions.values() for b in f.block_specializations.values() for op in b.operations}
print("ops", ops)
assert "conv" in ops and "linear" in ops and "relu" in ops, ops
# also a sklearn conversion (neural-network-free path)
from sklearn.linear_model import LinearRegression
lr = LinearRegression().fit(np.random.rand(20, 3), np.random.rand(20))
sm = ct.converters.sklearn.convert(lr, ["a", "b", "c"], "y")
sp = os.path.join(out, "lr.mlmodel"); sm.save(sp)
assert os.path.getsize(sp) > 100
print("CONVERT OK")
PY
timeout 1200 python $OUT/t.py $OUT 2>&1 | tee $OUT/log.txt
grep -q "CONVERT OK" $OUT/log.txt
echo "ORACLE PASS"
