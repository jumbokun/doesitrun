#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d /work/detr/.git ] || git clone https://github.com/facebookresearch/detr /work/detr
export UV_CACHE_DIR=/work/.uv-cache
[ -x /work/venv/bin/python ] || uv venv --python 3.12 /work/venv
# Only torch/torchvision are needed for hub inference (hubconf dependencies); CPU wheels.
uv pip install --python /work/venv/bin/python --index-url https://download.pytorch.org/whl/cpu \
  "torch==2.8.0" "torchvision==0.23.0"
uv pip install --python /work/venv/bin/python scipy packaging pillow requests numpy
export TORCH_HOME=/work/torch_home
mkdir -p "$TORCH_HOME/hub/checkpoints"
# Pre-download DETR checkpoint and the ImageNet ResNet-50 the backbone constructor fetches.
curl -fL -o "$TORCH_HOME/hub/checkpoints/detr-r50-e632da11.pth" -C - https://dl.fbaipublicfiles.com/detr/detr-r50-e632da11.pth || true
curl -fL -o "$TORCH_HOME/hub/checkpoints/resnet50-0676ba61.pth" -C - https://download.pytorch.org/models/resnet50-0676ba61.pth || true
mkdir -p /work/data
curl -fL -o /work/data/cats.jpg http://images.cocodataset.org/val2017/000000039769.jpg
cd /work && /work/venv/bin/python -c "import torch; torch.hub.load('/work/detr','detr_resnet50',source='local',pretrained=True)"
