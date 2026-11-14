#!/usr/bin/env bash
# Reproduce Depth-Anything-3 CPU setup from scratch.
set -euo pipefail
cd /work

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
# libGL / glib are required by opencv-python (cv2) and open3d
apt-get install -y -qq libgl1 libglib2.0-0 libgomp1

[ -d Depth-Anything-3/.git ] || git clone https://github.com/ByteDance-Seed/Depth-Anything-3 /work/Depth-Anything-3
cd /work/Depth-Anything-3

[ -x /work/venv/bin/python ] || uv venv -p 3.12 /work/venv
. /work/venv/bin/activate

# CPU-only torch wheels; PyPI as fallback for everything else
IDX=(--index-url https://download.pytorch.org/whl/cpu --extra-index-url https://pypi.org/simple --index-strategy unsafe-best-match)

# README: pip install xformers torch>=2 torchvision ; pip install -e .
uv pip install "${IDX[@]}" xformers "torch>=2" torchvision
uv pip install "${IDX[@]}" -e .
# Undeclared runtime dependency imported by depth_anything_3/model/da3.py
uv pip install "${IDX[@]}" addict

# Pre-download the model into the HF cache (public, no token)
python -c "from huggingface_hub import snapshot_download; snapshot_download('depth-anything/DA3-SMALL')"

python -c "import depth_anything_3.cli; print('setup ok')"
