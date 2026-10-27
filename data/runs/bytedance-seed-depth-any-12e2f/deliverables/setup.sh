#!/usr/bin/env bash
set -euxo pipefail
cd /work
export DEBIAN_FRONTEND=noninteractive
# open3d / opencv runtime libs
apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 libgomp1 libx11-6 libxext6 libxrender1 libegl1 libusb-1.0-0
[ -d Depth-Anything-3 ] || git clone https://github.com/ByteDance-Seed/Depth-Anything-3
cd Depth-Anything-3
[ -d /work/venv ] || uv venv --python 3.12 /work/venv
source /work/venv/bin/activate
# xformers is a hard dep in pyproject but is CUDA-only & optional at runtime -> drop it
echo "xformers; sys_platform == 'never'" > /work/overrides.txt
uv pip install --index-url https://download.pytorch.org/whl/cpu torch torchvision
uv pip install --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match \
    --override /work/overrides.txt -e .
# CLI defaults to --device cuda; add CPU fallback
python /work/patch_cpu.py /work/Depth-Anything-3
# undeclared runtime deps
uv pip install addict scikit-learn
# pre-download model weights
python -c "from huggingface_hub import snapshot_download; snapshot_download('depth-anything/DA3-SMALL')"
