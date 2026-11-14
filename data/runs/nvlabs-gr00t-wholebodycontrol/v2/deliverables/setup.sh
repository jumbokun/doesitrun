#!/usr/bin/env bash
# Reproduce the CPU-only motionbricks training setup.
set -euo pipefail
cd /work
if [ ! -d GR00T-WholeBodyControl ]; then
  # LFS objects (meshes/gifs/checkpoints) are not needed for synthetic-data training
  GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 https://github.com/NVlabs/GR00T-WholeBodyControl /work/GR00T-WholeBodyControl
fi
# README uses conda; uv venv with Python 3.10 is equivalent
[ -x /work/venv/bin/python ] || uv venv -p 3.10 /work/venv
. /work/venv/bin/activate
CPU_IDX=https://download.pytorch.org/whl/cpu
# CPU-only torch wheel (avoid pulling multi-GB CUDA wheels)
uv pip install "torch==2.14.1" --index-url "$CPU_IDX"
cd /work/GR00T-WholeBodyControl/motionbricks
uv pip install -e . pynput python-xlib \
  "torch==2.14.1" "pytorch-lightning==2.6.6" "vector-quantize-pytorch==1.34.0" \
  "transformers==5.20.2" "hydra-core==1.3.8" "numpy==2.2.6" "mujoco==3.17.0" "adam-atan2-pytorch==0.4.1" \
  --extra-index-url "$CPU_IDX" --index-strategy unsafe-best-match
python -c "import torch, motionbricks; print('torch', torch.__version__)"
