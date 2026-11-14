#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
[ -d demucs/.git ] || git clone https://github.com/facebookresearch/demucs /work/demucs
apt-get update -y && apt-get install -y --no-install-recommends ffmpeg
# torchaudio<2.1 has no Python 3.12 wheels -> use a uv-managed Python 3.11
uv venv --clear --python 3.11 /work/venv
export VIRTUAL_ENV=/work/venv PATH=/work/venv/bin:$PATH
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.0.1 torchaudio==2.0.2
uv pip install "numpy<2" "setuptools<81"
uv pip install -e /work/demucs
# Pre-download the default htdemucs weights into the torch hub cache
cd /tmp && python -c "from demucs.pretrained import get_model; get_model('htdemucs')"
