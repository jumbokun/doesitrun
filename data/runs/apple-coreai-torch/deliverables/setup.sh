#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d coreai-torch/.git ] || git clone https://github.com/apple/coreai-torch /work/coreai-torch
cd /work/coreai-torch
uv venv --python 3.12 /work/venv
# CPU-only torch from the PyTorch CPU index; everything else from PyPI
uv pip install --python /work/venv/bin/python \
  --index-url https://pypi.org/simple --extra-index-url https://download.pytorch.org/whl/cpu \
  --index-strategy unsafe-best-match \
  "torch==2.13.0" -e .
/work/venv/bin/python -c "import coreai_torch, coreai; print(coreai_torch.__version__)"
