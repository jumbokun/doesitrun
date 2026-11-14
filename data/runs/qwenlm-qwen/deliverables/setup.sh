#!/usr/bin/env bash
set -euxo pipefail
cd /work
[ -d Qwen/.git ] || git clone https://github.com/QwenLM/Qwen /work/Qwen
cd /work/Qwen
uv venv --clear --python 3.12 /work/venv
. /work/venv/bin/activate
# README requires pytorch>=1.12 but requirements.txt does not include it; install CPU wheel
uv pip install --index-url https://download.pytorch.org/whl/cpu "torch==2.4.1"
uv pip install -r requirements.txt "numpy<2" "huggingface_hub<0.26"
# Hugging Face repo Qwen/Qwen-1_8B-Chat no longer resolves (401); use ModelScope as the README's fallback
uv pip install modelscope
python - <<'PY'
from modelscope import snapshot_download
snapshot_download("qwen/Qwen-1_8B-Chat", local_dir="/work/models/Qwen-1_8B-Chat")
PY
