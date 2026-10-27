#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d /work/Qwen/.git ] || git clone https://github.com/QwenLM/Qwen /work/Qwen
cd /work/Qwen
export UV_LINK_MODE=copy
[ -x /work/venv/bin/python ] || uv venv --python 3.10 /work/venv
# README requires torch >= 1.12 but requirements.txt omits it; use CPU-only wheels
uv pip install --python /work/venv/bin/python --index-url https://download.pytorch.org/whl/cpu "torch==2.2.2"
uv pip install --python /work/venv/bin/python -r requirements.txt "numpy<2"

# Qwen/Qwen-1_8B-Chat is no longer available on Hugging Face (401 / repo not found).
# Fetch the official copy from ModelScope (qwen org) into ./Qwen/Qwen-1_8B-Chat so that
# `-c Qwen/Qwen-1_8B-Chat` resolves to this local directory when run from /work/Qwen.
MODEL_DIR=/work/Qwen/Qwen/Qwen-1_8B-Chat
if [ ! -f "$MODEL_DIR/model-00002-of-00002.safetensors" ]; then
  rm -rf "$MODEL_DIR"; mkdir -p /work/Qwen/Qwen
  git lfs install --skip-repo
  git clone https://www.modelscope.cn/qwen/Qwen-1_8B-Chat.git "$MODEL_DIR"
  git -C "$MODEL_DIR" checkout 8ccdac8
  rm -rf "$MODEL_DIR/.git"
fi
cd "$MODEL_DIR"
echo "afe102dfe02cbf973a5647a4ccef97dad0f088ae12a749e67000f25af3c6c997  model-00001-of-00002.safetensors
f710454106cacb0bee8138866573f1ecd453c3cd55f122b74e70a0e392d21435  model-00002-of-00002.safetensors" | sha256sum -c -
