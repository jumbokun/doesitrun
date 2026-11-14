#!/bin/bash
set -euo pipefail
cd /work
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq libgl1 libglib2.0-0 ninja-build python3-dev >/dev/null
[ -d /work/detectron2 ] || git clone https://github.com/facebookresearch/detectron2 /work/detectron2
git -C /work/detectron2 checkout 247691a1c292654867deb35cabb27f18d75a1363
rm -rf /work/venv; uv venv --python /usr/bin/python3 /work/venv
source /work/venv/bin/activate
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.5.1 torchvision==0.20.1
uv pip install opencv-python-headless setuptools wheel ninja pip
# CPU-only build; torch must be visible at build time -> no build isolation
export FORCE_CUDA=0 CUDA_VISIBLE_DEVICES=""
cd /work/detectron2
rm -rf build
# demo.py has a Meta-internal import path; make it importable from demo/
sed -i "s/^from vision.fair.detectron2.demo.predictor import/from predictor import/" demo/demo.py
python -m pip install --no-build-isolation -e .
# Pre-fetch checkpoint into fvcore cache and a test image
mkdir -p /work/test
curl -fsSL -o /work/test/input.jpg http://images.cocodataset.org/val2017/000000439715.jpg
python - <<'PY'
from detectron2.utils.file_io import PathManager
print(PathManager.get_local_path("detectron2://COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x/137849600/model_final_f10217.pkl"))
PY
