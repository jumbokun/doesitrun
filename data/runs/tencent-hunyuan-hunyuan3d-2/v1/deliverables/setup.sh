#!/usr/bin/env bash
set -euxo pipefail
cd /work
[ -d Hunyuan3D-2/.git ] || git clone https://github.com/Tencent-Hunyuan/Hunyuan3D-2 /work/Hunyuan3D-2
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 libgomp1
uv venv --python 3.12 /work/venv
. /work/venv/bin/activate
uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
cd /work/Hunyuan3D-2
uv pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match
uv pip install -e . --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match
# transformers 5.x renamed Dinov2 modules -> checkpoint keys no longer match
uv pip install "transformers>=4.48,<5" "diffusers<0.36" "huggingface_hub<1"
export HF_HOME=/work/hf_cache
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download('tencent/Hunyuan3D-2mini', allow_patterns=['hunyuan3d-dit-v2-mini-turbo/*','hunyuan3d-vae-v2-mini-turbo/*'])
PY
# Patch: enable_flashvdm() reloads the turbo VAE with ShapeVAE's default dtype (fp16),
# ignoring the pipeline dtype -> "mat1 and mat2 must have the same dtype" on CPU/float32.
cd /work/Hunyuan3D-2
grep -q 'device=self.device, dtype=self.dtype,' hy3dgen/shapegen/pipelines.py || \
  sed -i 's|^\(\s*\)device=self.device,$|\1device=self.device, dtype=self.dtype,|' hy3dgen/shapegen/pipelines.py
# Pre-fetch rembg u2net model (used by hy3dgen.rembg.BackgroundRemover)
export U2NET_HOME=/work/u2net
python -c "from rembg import new_session; new_session()"
