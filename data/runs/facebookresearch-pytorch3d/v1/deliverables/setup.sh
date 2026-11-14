#!/usr/bin/env bash
set -euxo pipefail
cd /work
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends python3-dev  # Python.h needed to build the C++ extension
[ -d pytorch3d/.git ] || git clone https://github.com/facebookresearch/pytorch3d /work/pytorch3d
# No conda in image: use uv venv with system Python 3.12 instead
uv venv --clear --python python3.12 /work/venv
. /work/venv/bin/activate
# CPU-only PyTorch within the documented supported range (2.4.1 has py3.12 wheels)
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.4.1 torchvision==0.19.1
uv pip install iopath "numpy<2" setuptools wheel ninja
cd /work/pytorch3d
# Force CPU-only extension even though CUDA toolkit exists in the image
export PYTORCH3D_FORCE_NO_CUDA=1 FORCE_CUDA=0 MAX_JOBS=$(nproc)
uv pip install --no-build-isolation -e .
python -c "import torch, pytorch3d, pytorch3d._C; print(pytorch3d.__version__)"
