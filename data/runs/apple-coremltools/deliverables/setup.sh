#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d coremltools/.git ] || git clone https://github.com/apple/coremltools /work/coremltools
rm -rf /work/venv
uv venv --python 3.12 /work/venv
. /work/venv/bin/activate
# torch <=2.8 (coremltools _TORCH_MAX_VERSION), CPU wheels; sklearn <=1.5.1 (_SKLEARN_MAX_VERSION)
uv pip install --index-url https://download.pytorch.org/whl/cpu --extra-index-url https://pypi.org/simple \
  --index-strategy unsafe-best-match "torch==2.7.1"
uv pip install "coremltools==9.0" "scikit-learn==1.5.1" "numpy<2.3"
python -c "import coremltools, torch, sklearn; print(coremltools.__version__, torch.__version__, sklearn.__version__)"
