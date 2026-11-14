#!/bin/bash
set -euxo pipefail
cd /work
[ -d Qwen3-TTS ] || git clone https://github.com/QwenLM/Qwen3-TTS /work/Qwen3-TTS
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y sox libsox-fmt-all libsndfile1 ffmpeg
uv venv --python 3.12 /work/venv
export VIRTUAL_ENV=/work/venv PATH=/work/venv/bin:$PATH
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.15.0 torchaudio==2.11.1
uv pip install -e /work/Qwen3-TTS "huggingface_hub[cli]"
export HF_HOME=/work/hf_cache
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice")
PY
