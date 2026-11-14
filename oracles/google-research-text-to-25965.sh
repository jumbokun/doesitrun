set -e
set -o pipefail
source /work/env.sh
cd /work/text-to-text-transfer-transformer
test -f t5/models/hf_model.py
# Run outside the clone so the installed t5 package is what gets imported (no shadowing by ./t5).
OUT=$(mktemp -d /tmp/t5_oracle.XXXXXX)
cd "$OUT"
cat > run.py <<'PY'
import sys
import torch
import t5
import t5.models
out = sys.argv[1]
# Usage example linked from README.md:96 (t5/models/hf_model.py:24-74): falls back to CPU when CUDA is absent.
device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
model = t5.models.HfPyTorchModel("t5-base", out + "/hft5/", device)
inputs = [
    "translate English to German: That is good.",
    "translate English to French: The house is wonderful.",
    "cola sentence: This is a totally valid sentence.",
    "cola sentence: A doggy detail was walking famously.",
]
# predict() signature: hf_model.py:458-466; writes one decoded line per input (hf_model.py:536-537)
model.predict(inputs, sequence_length={"inputs": 32}, batch_size=2, output_file=out + "/pred.txt")
PY
timeout 3000 python run.py "$OUT" 2>&1 | tail -40
test -s "$OUT/pred.txt"
python - "$OUT/pred.txt" <<'PY'
import sys
lines = [l.strip() for l in open(sys.argv[1]).read().splitlines()]
print("PREDICTIONS:", lines)
assert len(lines) == 4, lines
de, fr, cola1, cola2 = [l.lower() for l in lines]
# Pretrained T5 checkpoints were trained on the multi-task mixture incl. WMT en-de/en-fr and GLUE CoLA,
# so t5-base answers these task prefixes.
assert "gut" in de and "das" in de, de
assert "maison" in fr, fr
assert cola1 in ("acceptable", "unacceptable") and cola2 in ("acceptable", "unacceptable"), (cola1, cola2)
assert cola1 == "acceptable", cola1
PY
echo "ORACLE PASS"
