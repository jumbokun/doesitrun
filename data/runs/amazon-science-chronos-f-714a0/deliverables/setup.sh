#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d chronos-forecasting/.git ] || git clone https://github.com/amazon-science/chronos-forecasting /work/chronos-forecasting
uv venv --python 3.12 /work/.venv
. /work/.venv/bin/activate
# CPU-only torch wheel (avoid pulling multi-GB CUDA wheels on a GPU-less box)
uv pip install --index-url https://download.pytorch.org/whl/cpu torch
uv pip install -e /work/chronos-forecasting 'pandas[pyarrow]' huggingface_hub
export HF_HOME=/work/hf_cache
python -c "from huggingface_hub import snapshot_download; snapshot_download('amazon/chronos-2')"
