#!/usr/bin/env bash
set -euxo pipefail
cd /work
[ -d GFPGAN ] || git clone https://github.com/TencentARC/GFPGAN /work/GFPGAN
cd /work/GFPGAN
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libgl1 libglib2.0-0 wget
# Python 3.10: basicsr/facexlib/realesrgan are old and break on 3.12 / new torchvision
[ -x /work/venv/bin/python ] || uv venv --python 3.10 /work/venv
export VIRTUAL_ENV=/work/venv PATH=/work/venv/bin:$PATH
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.0.1 torchvision==0.15.2
uv pip install "numpy<2" setuptools wheel
uv pip install --no-build-isolation basicsr==1.4.2 facexlib==0.3.0 realesrgan==0.3.0
uv pip install --no-build-isolation -r requirements.txt "numpy<2" "opencv-python<4.11"
uv pip install --no-build-isolation -e .
# Pre-download weights
mkdir -p experiments/pretrained_models gfpgan/weights
cd experiments/pretrained_models
[ -s GFPGANv1.3.pth ] || wget -q https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.3.pth
cd /work/GFPGAN/gfpgan/weights
[ -s detection_Resnet50_Final.pth ] || wget -q https://github.com/xinntao/facexlib/releases/download/v0.1.0/detection_Resnet50_Final.pth
[ -s parsing_parsenet.pth ] || wget -q https://github.com/xinntao/facexlib/releases/download/v0.2.2/parsing_parsenet.pth
[ -s RealESRGAN_x2plus.pth ] || wget -q https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.1/RealESRGAN_x2plus.pth
