#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d python-fire/.git ] || git clone https://github.com/google/python-fire /work/python-fire
# README says `python setup.py install`, but the repo has no setup.py (pyproject.toml only)
[ -d /work/venv ] || uv venv --python python3 /work/venv
uv pip install --python /work/venv/bin/python /work/python-fire
