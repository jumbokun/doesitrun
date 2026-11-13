#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d gym/.git ] || git clone https://github.com/openai/gym /work/gym
git -C gym checkout -q bc212954
# README supports Python 3.7-3.10; system python is 3.12, so use uv-managed 3.10
uv venv --python 3.10 /work/.venv
# gym 0.26.2 uses np.bool8 (removed in NumPy 2.0) -> pin numpy<2
uv pip install --python /work/.venv/bin/python "numpy<2" -e /work/gym
