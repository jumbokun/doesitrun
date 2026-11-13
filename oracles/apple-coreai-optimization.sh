set -e
source /work/env.sh
cd /work/coreai-optimization
D=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $D/t.py <<'PY'
import torch
from coreai_opt.quantization import Quantizer, QuantizerConfig
from torch import nn
torch.manual_seed(0)
model = nn.Sequential(nn.Linear(128, 64), nn.ReLU(), nn.Linear(64, 10)).eval()
x = (torch.randn(1, 128),)
ref = model(*x)
config = QuantizerConfig.presets.w8()
q = Quantizer(model, config)
p = q.prepare(x)
f = q.finalize()
assert f is not None
print("finalized type:", type(f).__name__)
out = p(*x)
assert out.shape == (1, 10), out.shape
assert torch.isfinite(out).all()
assert torch.allclose(out, ref, atol=0.2), (out - ref).abs().max()
print("QUANT_OK", out.shape)
PY
timeout 1500 python -I $D/t.py 2>&1 | tee $D/out.txt
grep -q QUANT_OK $D/out.txt
echo ORACLE PASS
