#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
[ -d MegaTTS3/.git ] || git clone https://github.com/bytedance/MegaTTS3 /work/MegaTTS3
cd /work/MegaTTS3
git lfs pull || true
apt-get update && apt-get install -y --no-install-recommends ffmpeg libsndfile1
uv python install 3.10
[ -d /work/venv ] || uv venv --python 3.10 /work/venv
. /work/venv/bin/activate
# CPU-only torch wheels (requirements pin torch 2.6.0; default PyPI wheel pulls ~3GB of CUDA libs)
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.6.0 torchaudio==2.6.0
# setuptools>=81 dropped pkg_resources, which openai-whisper's setup.py needs at build time
echo "setuptools<81" > /tmp/build-constraints.txt
uv pip install --build-constraint /tmp/build-constraints.txt -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match
uv pip install "huggingface_hub<1"
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("ByteDance/MegaTTS3", local_dir="/work/MegaTTS3/checkpoints")
PY
