#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d /work/warp/.git ] || git clone --depth 1 https://github.com/NVIDIA/warp /work/warp
[ -x /work/venv/bin/python ] || uv venv --python python3 /work/venv
. /work/venv/bin/activate
uv pip install "warp-lang[examples]"
python -c "import warp, pxr; print('warp', warp.__version__)"
