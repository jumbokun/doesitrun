set -e
source /work/env.sh
cd /work/Model-Optimizer
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'PY'
import sys, torch
import modelopt.torch.quantization as mtq
from modelopt.torch.quantization.nn import TensorQuantizer
from transformers import LlamaConfig, LlamaForCausalLM
torch.manual_seed(0)
cfg = LlamaConfig(vocab_size=500, hidden_size=64, intermediate_size=128, num_hidden_layers=2,
                  num_attention_heads=4, num_key_value_heads=4, max_position_embeddings=128)
model = LlamaForCausalLM(cfg).eval()
data = [torch.randint(0, 500, (2, 32)) for _ in range(8)]
with torch.no_grad():
    ref = model(data[0]).logits.clone()
def loop(m):
    with torch.no_grad():
        for d in data: m(d)
model = mtq.quantize(model, mtq.INT8_DEFAULT_CFG, loop)
nq = [m for m in model.modules() if isinstance(m, TensorQuantizer)]
assert len(nq) >= 14, len(nq)
enabled = [q for q in nq if q.is_enabled]
assert enabled, "no enabled quantizers"
assert any(getattr(q, "amax", None) is not None for q in enabled), "no calibrated amax"
with torch.no_grad():
    out = model(data[0]).logits
assert out.shape == ref.shape and torch.isfinite(out).all()
diff = (out - ref).abs().max().item()
print("max diff", diff, "quantizers", len(nq))
assert 0 < diff < 1.0, diff
mtq.print_quant_summary(model)
print("QUANT_OK")
PY
timeout 900 python $OUT/t.py 2>&1 | tee $OUT/log.txt
grep -q QUANT_OK $OUT/log.txt
echo "ORACLE PASS"
