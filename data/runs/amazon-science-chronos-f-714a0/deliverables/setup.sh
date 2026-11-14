#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d chronos-forecasting/.git ] || git clone https://github.com/amazon-science/chronos-forecasting /work/chronos-forecasting
[ -x /work/venv/bin/python ] || uv venv --python 3.12 /work/venv
export VIRTUAL_ENV=/work/venv PATH=/work/venv/bin:$PATH
# CPU-only torch wheel (no GPU; avoids multi-GB CUDA wheels)
uv pip install --index-url https://download.pytorch.org/whl/cpu "torch>=2.2,<3"
uv pip install -e /work/chronos-forecasting "pandas[pyarrow]>=2.0,<4"
export HF_HOME=/work/hf_cache
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("amazon/chronos-2")
PY
