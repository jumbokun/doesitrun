#!/usr/bin/env bash
set -euo pipefail
cd /work
if [ ! -d FastPhotoStyle/.git ]; then
  git clone https://github.com/NVIDIA/FastPhotoStyle /work/FastPhotoStyle
fi
cd /work/FastPhotoStyle
git lfs pull 2>/dev/null || true
# sanity check bundled model is a real file (not an LFS pointer)
test "$(stat -c %s PhotoWCTModels/photo_wct.pth)" -gt 1000000

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends libgl1 libglib2.0-0

uv venv --python 3.12 /work/venv
uv pip install --python /work/venv/bin/python \
  --index-url https://download.pytorch.org/whl/cpu torch==2.5.1 torchvision==0.20.1
uv pip install --python /work/venv/bin/python \
  "numpy<2.3" scipy pillow opencv-contrib-python-headless==4.10.0.84

/work/venv/bin/python /work/tools/patch_cpu.py /work/FastPhotoStyle
echo "setup complete"
