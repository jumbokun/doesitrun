#!/usr/bin/env bash
# Reproduce the CPU-only PaddleFormers quickstart setup from scratch.
set -euo pipefail
cd /work
VENV=/work/.paddleformers-work

if [ ! -d /work/PaddleFormers/.git ]; then
  git clone https://github.com/PaddlePaddle/PaddleFormers.git /work/PaddleFormers
fi
cd /work/PaddleFormers
git checkout -q f7fa77f02e   # commit this setup was validated against

# CPU fixes (no paddlefleet, no fused RMSNorm kernel, no bf16 matmul on CPU)
if ! git apply --reverse --check /work/patches/cpu_no_paddlefleet.patch 2>/dev/null; then
  git apply /work/patches/cpu_no_paddlefleet.patch
fi

# --seed installs pip into the venv: paddleformers does `import pip` at runtime
[ -x "$VENV/bin/python" ] || uv venv --seed --python 3.12 "$VENV"
source "$VENV/bin/activate"

# README only documents CUDA wheels; use the official CPU index instead
uv pip install "paddlepaddle==3.3.1" \
  --index-url https://www.paddlepaddle.org.cn/packages/stable/cpu/ \
  --extra-index-url https://pypi.org/simple
uv pip install pip
# Source install without the [paddlefleet] extra (GPU-only, pinned version not published)
uv pip install -e .

# Pre-download the model (tokenizer + weights) into the HF cache
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("Qwen/Qwen3-0.6B-Base")
PY

# Smoke test
cd /tmp
python -c "
from paddleformers.transformers import AutoTokenizer
t = AutoTokenizer.from_pretrained('Qwen/Qwen3-0.6B-Base')
ids = t.encode('中华人民共和国'); print(ids)
assert list(ids) == [105492, 104773], ids
"
echo "setup complete"
