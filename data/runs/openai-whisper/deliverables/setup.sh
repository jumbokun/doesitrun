#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
[ -d whisper/.git ] || git clone https://github.com/openai/whisper /work/whisper
apt-get update -y && apt-get install -y --no-install-recommends ffmpeg
[ -d /work/venv ] || uv venv --python 3.12 /work/venv
. /work/venv/bin/activate
# CPU-only machine: install CPU torch wheel first to avoid multi-GB CUDA deps
uv pip install torch --index-url https://download.pytorch.org/whl/cpu
uv pip install /work/whisper
# pre-download the tiny.en model into the default cache
python -c "import whisper; whisper.load_model('tiny.en', device='cpu')"
