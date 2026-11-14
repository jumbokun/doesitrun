#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d PaddleNLP/.git ] || git clone --depth 1 https://github.com/PaddlePaddle/PaddleNLP /work/PaddleNLP
rm -rf /work/venv
uv venv -p 3.10 --seed /work/venv
. /work/venv/bin/activate
# README: install paddlepaddle (CPU) then `pip install paddlenlp==3.0.0b4`.
# Unpinned transitive deps (aistudio-sdk, datasets, ...) have since broken paddlenlp 3.0.0b4,
# so resolve against PyPI as of the b4 release (paddlepaddle 3.0.0 came out a week later).
uv pip install --exclude-newer 2025-03-20 --exclude-newer-package paddlepaddle=2025-04-30 \
  paddlepaddle==3.0.0 paddlenlp==3.0.0b4 setuptools pip \
  -i https://www.paddlepaddle.org.cn/packages/stable/cpu/ --extra-index-url https://pypi.org/simple \
  --index-strategy unsafe-best-match
# Pre-download Qwen/Qwen2-0.5B into ~/.paddlenlp cache
python - <<'PY'
from paddlenlp.transformers import AutoTokenizer, AutoModelForCausalLM
AutoTokenizer.from_pretrained("Qwen/Qwen2-0.5B")
AutoModelForCausalLM.from_pretrained("Qwen/Qwen2-0.5B", dtype="float32")
PY
echo "setup done"
