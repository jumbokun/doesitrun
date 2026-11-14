#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d coremltools/.git ] || git clone --depth 1 https://github.com/apple/coremltools /work/coremltools
[ -x /work/venv/bin/python ] || uv venv -p 3.12 /work/venv
# Prebuilt PyPI wheel (README path); pin torch/sklearn to versions coremltools supports
# (_TORCH_MAX_VERSION=2.8.0, _SKLEARN_MAX_VERSION=1.5.1 -> newer sklearn disables the converter).
VIRTUAL_ENV=/work/venv uv pip install --python /work/venv/bin/python \
  "coremltools==9.1.dev1" "torch==2.8.0" "scikit-learn==1.5.2" \
  --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match
