#!/bin/bash
set -euo pipefail
cd /work
[ -d Model-Optimizer ] || git clone --depth 1 https://github.com/NVIDIA/Model-Optimizer /work/Model-Optimizer
[ -d /work/venv ] || uv venv --python 3.12 /work/venv
source /work/venv/bin/activate
# CPU-only torch first so the editable install doesn't pull CUDA wheels
uv pip install --index-url https://download.pytorch.org/whl/cpu "torch>=2.10"
uv pip install -e /work/Model-Optimizer "transformers>=5.5,<5.19" "accelerate>=1.6.0" safetensors \
  --index-strategy unsafe-best-match --extra-index-url https://download.pytorch.org/whl/cpu
python -c "import modelopt.torch.quantization as mtq, torch, transformers; print(torch.__version__, transformers.__version__)"
