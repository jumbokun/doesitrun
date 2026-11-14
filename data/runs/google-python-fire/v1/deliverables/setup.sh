#!/usr/bin/env bash
# Reproducible setup for google/python-fire (CPU only).
set -euo pipefail
cd /work
if [ ! -d python-fire/.git ]; then
  git clone https://github.com/google/python-fire /work/python-fire
fi
# README says `python setup.py install`, but setup.py no longer exists (pyproject.toml only).
# Install from source with pip into a venv instead (system python is PEP 668 externally-managed).
uv venv --python python3 /work/.venv
uv pip install --python /work/.venv/bin/python /work/python-fire
