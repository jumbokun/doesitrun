#!/bin/bash
# Reproduces the coreai-opt environment (CPU-only) from scratch.
set -euo pipefail
cd /work
[ -d coreai-optimization ] || git clone https://github.com/apple/coreai-optimization /work/coreai-optimization
rm -rf /work/venv
uv venv --python 3.12 /work/venv
PY=/work/venv/bin/python
# CPU-only torch; pin to 2.13.x (coreai-torch is validated with torch<=2.13).
uv pip install --python $PY --index-url https://download.pytorch.org/whl/cpu "torch>=2.13,<2.14"
# coreai-opt with the [coreai] extra: finalize() requires coreai-torch.
uv pip install --python $PY --extra-index-url https://download.pytorch.org/whl/cpu \
    --index-strategy unsafe-best-match "torch>=2.13,<2.14" "coreai-opt[coreai]"
$PY -c "import torch, torchao, coreai_opt, coreai_torch; print('torch', torch.__version__, 'torchao', torchao.__version__)"
