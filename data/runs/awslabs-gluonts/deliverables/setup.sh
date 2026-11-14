#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d /work/gluonts/.git ] || git clone https://github.com/awslabs/gluonts /work/gluonts
uv venv --python 3.12 /work/venv
export VIRTUAL_ENV=/work/venv PATH=/work/venv/bin:$PATH
# CPU-only torch wheel (avoid multi-GB CUDA wheels); then gluonts[torch] from the clone
uv pip install --index-url https://download.pytorch.org/whl/cpu "torch>=2.10,<3"
uv pip install "/work/gluonts[torch]" matplotlib
python -c "import gluonts, torch; print(gluonts.__version__, torch.__version__)"
