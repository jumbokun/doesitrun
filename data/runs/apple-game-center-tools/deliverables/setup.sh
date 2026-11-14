#!/bin/bash
set -euo pipefail
cd /work
[ -d game-center-tools ] || git clone https://github.com/apple/game-center-tools /work/game-center-tools
uv venv --allow-existing /work/venv
uv pip install --python /work/venv/bin/python requests
