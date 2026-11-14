#!/usr/bin/env bash
set -euo pipefail
cd /work
if [ ! -d app-store-server-library-python/.git ]; then
  git clone https://github.com/apple/app-store-server-library-python /work/app-store-server-library-python
fi
uv venv --python 3.12 /work/venv
uv pip install --python /work/venv/bin/python /work/app-store-server-library-python
