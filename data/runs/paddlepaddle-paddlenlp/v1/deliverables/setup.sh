#!/usr/bin/env bash
# Reproduce PaddleNLP (CPU) setup for the README Qwen2-0.5B quick-start.
set -euo pipefail
cd /work
[ -d /work/PaddleNLP/.git ] || git clone --depth 1 https://github.com/PaddlePaddle/PaddleNLP /work/PaddleNLP

# Python 3.10 venv with pip/setuptools seeded (paddle imports setuptools, paddlenlp imports pip)
[ -x /work/venv/bin/python ] || uv venv -p 3.10 --seed /work/venv
source /work/venv/bin/activate

# README: pip install paddlenlp==3.0.0b4. Its deps are unpinned and newer releases
# (e.g. aistudio-sdk 0.3.x) break the import, so resolve deps as of the b4 release date.
uv pip install --exclude-newer 2025-03-20 paddlenlp==3.0.0b4 setuptools
# CPU PaddlePaddle (README requires paddlepaddle>=3.0.0rc1)
uv pip install paddlepaddle==3.0.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/

source /work/env.sh
# Pre-download the model/tokenizer into $PPNLP_HOME
mkdir -p /tmp/ppnlp_dl && cd /tmp/ppnlp_dl
python - <<'PY'
from paddlenlp.transformers import AutoTokenizer, AutoModelForCausalLM
AutoTokenizer.from_pretrained("Qwen/Qwen2-0.5B")
AutoModelForCausalLM.from_pretrained("Qwen/Qwen2-0.5B", dtype="float32")
print("model downloaded")
PY
