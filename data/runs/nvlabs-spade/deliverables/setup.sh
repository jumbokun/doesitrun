#!/usr/bin/env bash
# Reproduces the SPADE setup (CPU only). Run as root on a fresh image.
set -euo pipefail
cd /work
[ -d SPADE/.git ] || git clone https://github.com/NVlabs/SPADE.git SPADE
cd SPADE

# Python env: README targets py3.6/torch1.0; modern CPU-only torch works unmodified.
[ -x /work/venv/bin/python ] || uv venv -p 3.12 /work/venv
. /work/venv/bin/activate
uv pip install --index-url https://download.pytorch.org/whl/cpu torch torchvision
uv pip install -r requirements.txt gdown

# sync_batchnorm, per README
if [ ! -d models/networks/sync_batchnorm ]; then
  (cd models/networks && rm -rf Synchronized-BatchNorm-PyTorch \
    && git clone https://github.com/vacancy/Synchronized-BatchNorm-PyTorch \
    && cp -rf Synchronized-BatchNorm-PyTorch/sync_batchnorm .)
fi

# Pretrained checkpoints (README Google Drive link). As of 2026-10 this file returns
# HTTP 404 (upstream issue #175) and no public mirror exists, so this step fails.
mkdir -p checkpoints
if [ ! -d checkpoints/coco_pretrained ]; then
  dl=$(mktemp -d)
  if gdown 12gvlTbMvUcJewQlSEaZdeb2CdOB-b8kQ -O "$dl/checkpoints.tar.gz" \
     || curl -fL "https://drive.usercontent.google.com/download?id=12gvlTbMvUcJewQlSEaZdeb2CdOB-b8kQ&export=download&confirm=t" -o "$dl/checkpoints.tar.gz"; then
    tar xzf "$dl/checkpoints.tar.gz" -C checkpoints
    rm -rf "$dl"
  else
    echo "ERROR: pretrained checkpoints.tar.gz is no longer downloadable (Google Drive 404)." >&2
    exit 1
  fi
fi
echo "Setup complete."
