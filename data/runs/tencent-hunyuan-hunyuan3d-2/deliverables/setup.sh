#!/usr/bin/env bash
set -euxo pipefail
cd /work
export HF_HOME=/work/hf_cache
[ -d Hunyuan3D-2/.git ] || git clone https://github.com/Tencent-Hunyuan/Hunyuan3D-2 /work/Hunyuan3D-2
# opencv/pymeshlab runtime libs
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 libgomp1 && rm -rf /var/lib/apt/lists/*
[ -d venv ] || uv venv --python 3.12 /work/venv
source /work/venv/bin/activate
cd /work/Hunyuan3D-2
uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
uv pip install -r requirements.txt
uv pip install -e .
# transformers 5.x renamed Dinov2 modules -> state_dict mismatch; pin to 4.x (and diffusers to a version compatible with huggingface_hub<1)
uv pip install "transformers>=4.48,<5" "diffusers<0.36"
# pre-download weights
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download('tencent/Hunyuan3D-2mini', allow_patterns=['hunyuan3d-dit-v2-mini-turbo/*'])
PY
