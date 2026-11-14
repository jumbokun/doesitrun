#!/bin/bash
set -euo pipefail
cd /work
[ -d garak ] || git clone --depth 1 https://github.com/NVIDIA/garak /work/garak
uv venv --python 3.12 /work/venv
source /work/venv/bin/activate
# CPU-only torch to avoid multi-GB CUDA wheels (no GPU here)
uv pip install --index-url https://download.pytorch.org/whl/cpu torch
uv pip install -e /work/garak --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match
