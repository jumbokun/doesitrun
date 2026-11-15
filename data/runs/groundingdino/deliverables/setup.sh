#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
[ -d GroundingDINO/.git ] || git clone https://github.com/IDEA-Research/GroundingDINO.git
cd GroundingDINO
# libGL etc. for opencv
apt-get update -qq && apt-get install -y -qq libgl1 libglib2.0-0 python3-dev >/dev/null
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export TORCH_CUDA_ARCH_LIST="12.0"
[ -d /work/venv ] || uv venv -p 3.12 /work/venv
source /work/venv/bin/activate
# Blackwell (sm_120) needs a cu128 torch build
uv pip install torch==2.7.1 torchvision==0.22.1 --index-url https://download.pytorch.org/whl/cu128
uv pip install setuptools wheel "transformers==4.44.2" "numpy<2.3" addict yapf timm opencv-python "supervision>=0.22.0" pycocotools
# torch>=2.6 removed DeprecatedTypeProperties->ScalarType conversion used by AT_DISPATCH
sed -i 's/AT_DISPATCH_FLOATING_TYPES(value\.type()/AT_DISPATCH_FLOATING_TYPES(value.scalar_type()/g' groundingdino/models/GroundingDINO/csrc/MsDeformAttn/ms_deform_attn_cuda.cu
# build the CUDA extension against the installed torch (no build isolation)
FORCE_CUDA=1 uv pip install --no-build-isolation -e .
# _C links against libc10.so, which is only resolvable once torch is loaded
grep -q '^import torch' groundingdino/__init__.py || echo 'import torch  # noqa: F401  (loads libc10 so `from groundingdino import _C` works)' >> groundingdino/__init__.py
python -c "from groundingdino import _C; print('_C ok')"
mkdir -p weights
[ -s weights/groundingdino_swint_ogc.pth ] || curl -fsSL --retry 3 -o weights/groundingdino_swint_ogc.pth \
  https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth
# pre-cache bert-base-uncased (text encoder) used by the config
python -c "from transformers import AutoTokenizer, BertModel; AutoTokenizer.from_pretrained('bert-base-uncased'); BertModel.from_pretrained('bert-base-uncased')"
