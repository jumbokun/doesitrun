#!/usr/bin/env bash
set -euo pipefail
cd /work
if [ ! -d /work/warp/.git ]; then
  git clone --depth 1 https://github.com/NVIDIA/warp /work/warp
fi
uv venv --python python3 /work/.venv
uv pip install --python /work/.venv/bin/python pip "warp-lang[examples]"
/work/.venv/bin/python -c "import warp as wp, pxr; wp.init(); print(wp.__version__)"
