#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d vggt/.git ] || git clone https://github.com/facebookresearch/vggt /work/vggt
cd /work/vggt
uv venv --python 3.12 /work/venv
. /work/venv/bin/activate
# CPU-only torch wheels (README pins torch 2.3.1/torchvision 0.18.1; default index pulls CUDA builds)
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.3.1 torchvision==0.18.1
uv pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match
# make `import vggt` work from anywhere
uv pip install --no-deps -e .
export HF_HOME=/work/hf_cache
python -c "from huggingface_hub import snapshot_download; snapshot_download('facebook/VGGT-1B')"
