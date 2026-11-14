#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d Qwen3 ] || git clone --depth 1 https://github.com/QwenLM/Qwen3 /work/Qwen3
[ -d /work/venv ] || uv venv --python 3.12 /work/venv
. /work/venv/bin/activate
uv pip install --index-url https://download.pytorch.org/whl/cpu torch
uv pip install "transformers>=4.51.0" accelerate huggingface_hub
python -c "from huggingface_hub import snapshot_download; snapshot_download('Qwen/Qwen3-0.6B')"
