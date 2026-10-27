#!/usr/bin/env bash
set -euo pipefail
cd /work
if [ ! -d timesfm/.git ]; then
  git clone https://github.com/google-research/timesfm.git timesfm
fi
cd timesfm
uv venv --python python3 .venv
source .venv/bin/activate
# CPU-only torch (no GPU in this environment)
uv pip install --index-url https://download.pytorch.org/whl/cpu torch
uv pip install -e ".[torch]"
# Pre-download the TimesFM 3.0 checkpoint (public, no token)
export HF_HOME=/work/hf_cache
python - <<'PY'
from huggingface_hub import snapshot_download
print(snapshot_download("google/timesfm-3.0-pytorch"))
PY
