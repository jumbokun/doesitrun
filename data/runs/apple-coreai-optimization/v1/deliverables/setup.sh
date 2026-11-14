#!/usr/bin/env bash
# Reproducible CPU-only setup for apple/coreai-optimization (coreai-opt).
set -euo pipefail
cd /work
[ -d coreai-optimization/.git ] || git clone https://github.com/apple/coreai-optimization /work/coreai-optimization
command -v uv >/dev/null || { curl -LsSf https://astral.sh/uv/install.sh | sh; export PATH="$HOME/.local/bin:$PATH"; }
rm -rf /work/venv
uv venv -p 3.12 /work/venv
. /work/venv/bin/activate
# CPU-only torch, pinned to a version tested by coreai-opt CI (torch_2_13 group) and validated by coreai-torch (<=2.13)
uv pip install "torch==2.13.0" --index-url https://download.pytorch.org/whl/cpu
# coreai-opt from PyPI as documented, plus the [coreai] extra: finalize() needs coreai-torch
uv pip install "coreai-opt[coreai]" "torch==2.13.0" "torchao==0.18.0" \
  --index-url https://pypi.org/simple --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match
python -c "import torch, coreai_opt, coreai_torch; print('torch', torch.__version__)"
