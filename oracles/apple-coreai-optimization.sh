set -e
source /work/env.sh
# src/ layout (src/coreai_opt), so running from the repo root does not shadow the installed package.
cd /work/coreai-optimization
D=$(mktemp -d /tmp/oracle.XXXXXX)
cat > "$D/t.py" <<'PY'
import torch
from coreai_opt.quantization import Quantizer, QuantizerConfig
from torch import nn
torch.manual_seed(0)
# README "Usage" snippet, verbatim model / preset / calls
model = nn.Sequential(nn.Linear(128, 64), nn.ReLU(), nn.Linear(64, 10)).eval()
example_inputs = (torch.randn(1, 128),)
with torch.no_grad():
    ref = model(*example_inputs)
config = QuantizerConfig.presets.w8()
quantizer = Quantizer(model, config)
prepared_model = quantizer.prepare(example_inputs)
with torch.no_grad():
    pout = prepared_model(*example_inputs)
finalized_model = quantizer.finalize()
assert finalized_model is not None
print("finalized type:", type(finalized_model).__name__)
# The repo's own end-to-end preset test calls the finalized model directly
# (tests/test_quantization_preset.py:258-266), so it must run on CPU.
with torch.no_grad():
    fout = finalized_model(*example_inputs)
for name, out in (("prepared", pout), ("finalized", fout)):
    assert tuple(out.shape) == (1, 10), (name, out.shape)
    assert torch.isfinite(out).all(), name
    err = (out - ref).abs().max().item()
    print(name, "max abs err vs float:", err)
    # INT8 per-channel weight quantization: small but non-zero error
    assert err < 0.05, (name, err)
# finalize() replaces fake-quant with Core AI quantized ops (quantizer.py:526-533); the int8 weights
# must actually change the result, otherwise nothing was quantized.
assert (fout - ref).abs().max().item() > 0, "finalized output identical to float model"
print("QUANT_OK", tuple(fout.shape))
PY
timeout 1500 python "$D/t.py" 2>&1 | tee "$D/out.txt"
grep -q QUANT_OK "$D/out.txt"
echo ORACLE PASS
