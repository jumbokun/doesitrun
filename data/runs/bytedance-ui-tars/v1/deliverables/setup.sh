#!/bin/bash
set -euo pipefail
cd /work
[ -d UI-TARS ] || git clone https://github.com/bytedance/UI-TARS /work/UI-TARS
uv venv --clear --python 3.12 /work/.venv
uv pip install --python /work/.venv/bin/python /work/UI-TARS/codes "pillow>=11.2.1" "matplotlib>=3.10.3"
