#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
[ -d Qwen3-TTS ] || git clone https://github.com/QwenLM/Qwen3-TTS /work/Qwen3-TTS
# sox CLI (python 'sox' package shells out to it) and libsndfile for soundfile
apt-get update && apt-get install -y --no-install-recommends sox libsox-fmt-all libsndfile1 ffmpeg
uv venv --python 3.12 /work/venv
. /work/venv/bin/activate
# CPU-only torch (pyproject doesn't list torch; default wheel would pull CUDA libs)
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.8.0 torchaudio==2.8.0
uv pip install -e /work/Qwen3-TTS "huggingface_hub[cli]"
# make sure torch stays the CPU build
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.8.0 torchaudio==2.8.0
export HF_HOME=/work/hf_cache
hf download Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice
hf download Qwen/Qwen3-TTS-Tokenizer-12Hz
