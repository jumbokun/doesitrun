#!/bin/bash
set -euo pipefail
cd /work
[ -d app-store-server-library-python ] || git clone https://github.com/apple/app-store-server-library-python
uv venv --python 3.12 /work/venv
uv pip install --python /work/venv/bin/python /work/app-store-server-library-python
