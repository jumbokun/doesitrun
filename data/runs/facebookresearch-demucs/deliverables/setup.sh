#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
[ -d demucs/.git ] || git clone https://github.com/facebookresearch/demucs /work/demucs
apt-get update
apt-get install -y --no-install-recommends ffmpeg libsndfile1
# torchaudio<2.1 (pinned by demucs) has no wheels for Python 3.12 -> use 3.11 via uv
uv venv --clear --python 3.11 /work/venv
. /work/venv/bin/activate
uv pip install --index-url https://download.pytorch.org/whl/cpu "torch==2.0.1" "torchaudio==2.0.2"
uv pip install "numpy<2" soundfile "setuptools<81"
uv pip install -e /work/demucs
# pre-download default htdemucs weights into torch hub cache
cd /tmp && python -c "from demucs.pretrained import get_model; get_model('htdemucs')"
