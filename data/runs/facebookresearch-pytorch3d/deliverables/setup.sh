#!/usr/bin/env bash
set -euxo pipefail
cd /work
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y python3-dev  # Python.h needed to compile the C++ extension
[ -d pytorch3d/.git ] || git clone https://github.com/facebookresearch/pytorch3d.git /work/pytorch3d
cd /work/pytorch3d && git lfs pull || true
cd /work
# Python 3.12 venv; torch 2.4.1 (newest version listed as supported in INSTALL.md) CPU wheels
rm -rf /work/venv
uv venv --python /usr/bin/python3.12 /work/venv
uv pip install --python /work/venv/bin/python \
  --index-url https://download.pytorch.org/whl/cpu \
  --extra-index-url https://pypi.org/simple \
  torch==2.4.1 torchvision==0.19.1 "numpy<2"
uv pip install --python /work/venv/bin/python iopath setuptools wheel ninja matplotlib imageio
# Build CPU-only extension from the local clone; no build isolation so it sees the installed torch.
cd /work/pytorch3d
FORCE_CUDA=0 MAX_JOBS=$(nproc) uv pip install --python /work/venv/bin/python --no-build-isolation -e .
