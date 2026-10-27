#!/usr/bin/env bash
# Reproduce the full setup for NVlabs/stylegan2-ada-pytorch on an RTX 5060 (Blackwell, sm_120).
# Run as root on a fresh Ubuntu 24.04 + CUDA 12.8 devel sandbox.
set -euo pipefail

REPO_DIR=/work/stylegan2-ada-pytorch
VENV_DIR=/work/venv
REPO_URL=https://github.com/NVlabs/stylegan2-ada-pytorch
REPO_COMMIT=d72cc7d041b42ec8e806021a205ed9349f87c6a4
NETWORK_URL=https://nvlabs-fi-cdn.nvidia.com/stylegan2-ada-pytorch/pretrained/metfaces.pkl

export DEBIAN_FRONTEND=noninteractive
export PATH="/usr/local/cuda/bin:${PATH}"

# ---------------------------------------------------------------- system deps
# The base image already carries build-essential/git/curl/python3; this is just
# a belt-and-braces check so the script also works on a barer image.
if ! command -v g++ >/dev/null || ! command -v git >/dev/null || ! command -v curl >/dev/null; then
    apt-get update
    apt-get install -y --no-install-recommends build-essential git curl ca-certificates
fi
command -v nvcc >/dev/null || { echo "nvcc not found in PATH (need the CUDA devel toolkit)"; exit 1; }

# ------------------------------------------------------------------ the repo
if [ ! -d "${REPO_DIR}/.git" ]; then
    git clone "${REPO_URL}" "${REPO_DIR}"
fi
git -C "${REPO_DIR}" fetch --depth 1 origin "${REPO_COMMIT}" 2>/dev/null || true
git -C "${REPO_DIR}" checkout --quiet "${REPO_COMMIT}"

# ------------------------------------------------------------ python env
# The README asks for Python 3.7 + PyTorch 1.7.1, which has no sm_120 support
# at all. We use Python 3.11 + PyTorch 2.8.0 built against CUDA 12.8, which is
# the oldest easily available combination that can emit sm_120 code. The repo
# source itself needs no changes.
uv venv --python 3.11 "${VENV_DIR}"
# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

uv pip install --index-url https://download.pytorch.org/whl/cu128 "torch==2.8.0"
# README's library list (minus imageio-ffmpeg's hard pin, which has no 3.11 wheel),
# plus numpy<2 because the repo predates the numpy 2 ABI/API break.
uv pip install \
    "click==8.5.0" \
    "requests==2.34.2" \
    "tqdm==4.70.1" \
    "pyspng==0.1.4" \
    "ninja==1.13.2" \
    "imageio-ffmpeg==0.6.0" \
    "numpy==1.26.4" \
    "scipy==1.17.1" \
    "pillow==12.3.0"

# --------------------------------------------------- pretrained network pickle
# generate.py streams the pickle through dnnlib's URL cache; pre-populate that
# cache so verification does not depend on the CDN being reachable.
( cd "${REPO_DIR}" && python - "${NETWORK_URL}" <<'PY'
import sys, dnnlib
with dnnlib.util.open_url(sys.argv[1], cache=True) as f:
    print('cached', sys.argv[1], f.read(8) and 'ok')
PY
)

# ------------------------------------------- pre-build the custom CUDA plugins
# Optional: compiles bias_act/upfirdn2d into ~/.cache/torch_extensions so the
# first real run is fast. Needs a GPU; never fatal if one is not attached yet.
( cd "${REPO_DIR}" && python generate.py --outdir=/tmp/setup-warmup --trunc=1 --seeds=85 \
    --network="${NETWORK_URL}" ) || echo "WARNING: plugin pre-build skipped/failed; it will happen on first run"

echo "setup.sh done. Source /work/env.sh before running generate.py."
