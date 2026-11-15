#!/usr/bin/env bash
# Reproducible setup for GroundingDINO (Swin-T OGC) with the CUDA extension (groundingdino._C)
# compiled for an RTX 5060 Laptop GPU (Blackwell, sm_120) on Ubuntu 24.04 + CUDA 12.8.
# Run as root on a fresh container:  bash /work/setup.sh
set -euxo pipefail

REPO_DIR=/work/GroundingDINO
VENV=/work/venv
GD_COMMIT=856dde20aee659246248e20734ef9ba5214f5e44   # "Grounded SAM 2 Release", tested revision
export CUDA_HOME=${CUDA_HOME:-/usr/local/cuda}
export TORCH_CUDA_ARCH_LIST=12.0                     # sm_120 (Blackwell); nvcc 12.8 supports it
export HF_HOME=/work/hf-cache
export DEBIAN_FRONTEND=noninteractive
export MAX_JOBS=${MAX_JOBS:-4}

# --- 1. system packages -------------------------------------------------------
# python3-dev: Python.h is needed to compile the extension
# patchelf:    stamp torch/lib into the extension's RPATH (see NOTES.md)
# libgl1/libglib2.0-0/libxcb1: shared libs opencv-python (a requirements.txt dep) links against
apt-get update -qq
apt-get install -y -qq python3-dev patchelf libgl1 libglib2.0-0 libxcb1

# --- 2. clone -----------------------------------------------------------------
if [ ! -d "$REPO_DIR/.git" ]; then
  git clone https://github.com/IDEA-Research/GroundingDINO.git "$REPO_DIR"
fi
cd "$REPO_DIR"
git fetch --all --quiet || true
git checkout --quiet "$GD_COMMIT"

# --- 3. python environment ----------------------------------------------------
uv venv --python 3.12 "$VENV"
# shellcheck disable=SC1091
source "$VENV/bin/activate"
uv pip install pip ninja

# torch/torchvision built for CUDA 12.8 -> has sm_120 kernels (default PyPI wheels do not)
uv pip install torch==2.8.0 torchvision==0.23.0 --index-url https://download.pytorch.org/whl/cu128

# transformers must stay on 4.x: v5 dropped BertModel.get_extended_attention_mask,
# which groundingdino/models/GroundingDINO/bertwarper.py requires.
uv pip install "transformers==4.46.3"

# --- 4. source patches needed to build against torch 2.8 ----------------------
# AT_DISPATCH_FLOATING_TYPES no longer accepts Tensor::type() (DeprecatedTypeProperties)
sed -i 's/AT_DISPATCH_FLOATING_TYPES(value\.type()/AT_DISPATCH_FLOATING_TYPES(value.scalar_type()/' \
  groundingdino/models/GroundingDINO/csrc/MsDeformAttn/ms_deform_attn_cuda.cu
grep -c 'AT_DISPATCH_FLOATING_TYPES(value.scalar_type()' \
  groundingdino/models/GroundingDINO/csrc/MsDeformAttn/ms_deform_attn_cuda.cu
# make "import groundingdino._C" work on its own (libtorch must be loaded first)
printf 'import torch  # noqa: F401  # load libc10/libtorch before groundingdino._C\n' \
  > groundingdino/__init__.py

# --- 5. build + install (README step 3, with build isolation off) -------------
# pip's isolated build env cannot see torch, and setup.py imports torch at build time.
pip install --no-build-isolation -e .

# RPATH so the extension finds libc10.so/libtorch*.so without torch being imported first
TORCH_LIB="$(python -c 'import os,torch;print(os.path.join(os.path.dirname(torch.__file__),"lib"))')"
patchelf --set-rpath "$TORCH_LIB" "$REPO_DIR"/groundingdino/_C.cpython-*-linux-gnu.so

# --- 6. checkpoint (README step 4) --------------------------------------------
mkdir -p "$REPO_DIR/weights"
if [ ! -s "$REPO_DIR/weights/groundingdino_swint_ogc.pth" ]; then
  curl -fL --retry 5 --retry-delay 5 -o "$REPO_DIR/weights/groundingdino_swint_ogc.pth" \
    https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth
fi
echo "3b3ca2563c77c69f651d7bd133e97139c186df06231157a64c507099c52bc799  $REPO_DIR/weights/groundingdino_swint_ogc.pth" | sha256sum -c -

# --- 7. pre-fetch the BERT text encoder the config asks for -------------------
mkdir -p "$HF_HOME"
python - <<'PY'
from transformers import AutoTokenizer, BertConfig, BertModel
AutoTokenizer.from_pretrained("bert-base-uncased")
BertModel.from_pretrained("bert-base-uncased", config=BertConfig.from_pretrained("bert-base-uncased"))
print("bert-base-uncased cached")
PY

# --- 8. smoke test ------------------------------------------------------------
python -c "import groundingdino._C as c; print('groundingdino._C ok:', c.__file__)"
python -c "import torch; print('cuda', torch.cuda.is_available(), torch.cuda.get_device_capability())"
set +x
echo "setup.sh done. Source /work/env.sh before running the demo."
