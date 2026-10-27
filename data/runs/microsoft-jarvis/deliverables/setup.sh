#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d JARVIS/.git ] || git clone --depth 1 https://github.com/microsoft/JARVIS /work/JARVIS
cd /work/JARVIS/taskbench
# README uses conda python 3.8; use uv-managed python 3.8 instead (conda not in image)
uv venv --python 3.8 /work/venv
uv pip install --python /work/venv/bin/python -r requirements.txt
