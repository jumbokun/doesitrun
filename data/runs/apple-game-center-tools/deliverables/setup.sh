#!/bin/bash
set -euo pipefail
cd /work
[ -d game-center-tools ] || git clone https://github.com/apple/game-center-tools /work/game-center-tools
uv venv --python python3 /work/.venv
uv pip install --python /work/.venv/bin/python requests
chmod +x /work/game-center-tools/scripts/*.py
