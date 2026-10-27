#!/usr/bin/env bash
# Reproducible CPU-only setup for Hunyuan3D-2.1 shape generation (hy3dshape).
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
WORK=/work
REPO=$WORK/Hunyuan3D-2.1
VENV=$WORK/venv
export HY3DGEN_MODELS=${HY3DGEN_MODELS:-/root/.cache/hy3dgen}

# 1. System libs needed by pymeshlab / opencv / open3d (libGL, glib, EGL, OpenMP)
apt-get update
apt-get install -y --no-install-recommends libgl1 libglib2.0-0t64 libegl1 libgomp1 ca-certificates

# 2. Clone
if [ ! -d "$REPO/.git" ]; then
  git clone https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1 "$REPO"
fi

# 3. Python 3.10 venv (README tests with 3.10) + CPU build of the documented torch version
uv venv -p 3.10 --allow-existing "$VENV"
# shellcheck disable=SC1091
source "$VENV/bin/activate"
uv pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
  --index-url https://download.pytorch.org/whl/cpu

# 4. requirements.txt minus the Chinese mirror extra-index lines and bpy==4.0
#    (no bpy==4.0 wheel resolvable; bpy is only used by the texture/paint stage)
grep -v -e '^--extra-index-url' -e '^bpy' "$REPO/requirements.txt" > "$WORK/requirements.cpu.txt"
uv pip install -r "$WORK/requirements.cpu.txt"
# keep the CPU torch (guard against any requirement pulling a CUDA build)
uv pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
  --index-url https://download.pytorch.org/whl/cpu

# 5. Patch: low-memory checkpoint loading (mmap + build DiT in target dtype).
#    Without this, loading the 3.3B-param DiT in fp32 is OOM-killed on a 16 GB CPU box.
cd "$REPO"
python - <<'PY'
p = 'hy3dshape/hy3dshape/pipelines.py'
s = open(p).read()
old = """            ckpt = torch.load(ckpt_path, map_location='cpu', weights_only=True)
        # load model
        model = instantiate_from_config(config['model'])
"""
new = """            ckpt = torch.load(ckpt_path, map_location='cpu', weights_only=True, mmap=True)
        # load model (build the large DiT directly in the target dtype to limit peak RAM on CPU)
        default_dtype = torch.get_default_dtype()
        if dtype is not None and dtype.is_floating_point:
            torch.set_default_dtype(dtype)
        try:
            model = instantiate_from_config(config['model'])
        finally:
            torch.set_default_dtype(default_dtype)
"""
if new in s:
    print('pipelines.py already patched')
else:
    assert old in s, 'unexpected pipelines.py content'
    open(p, 'w').write(s.replace(old, new))
    print('pipelines.py patched')
PY

# 6. Download only the shape DiT weights into the location smart_load_model() checks first
python - <<'PY'
import os
from huggingface_hub import snapshot_download
base = os.path.expanduser(os.environ.get('HY3DGEN_MODELS', '~/.cache/hy3dgen'))
snapshot_download('tencent/Hunyuan3D-2.1',
                  allow_patterns=['hunyuan3d-dit-v2-1/*'],
                  local_dir=os.path.join(base, 'tencent/Hunyuan3D-2.1'))
PY
ls -la "$HY3DGEN_MODELS/tencent/Hunyuan3D-2.1/hunyuan3d-dit-v2-1"
echo "setup done"
