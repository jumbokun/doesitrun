#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ffmpeg libsndfile1 python3-venv
cd /work
[ -d earshot/.git ] || git clone https://github.com/Leonxlnx/earshot /work/earshot
cd /work/earshot
[ -x .venv/bin/python ] || python3 -m venv .venv
.venv/bin/python -m pip install -q --upgrade pip
.venv/bin/python -m pip install torch --index-url https://download.pytorch.org/whl/cpu
.venv/bin/python -m pip install -e ".[mcp,llm,dev]"
# download both pinned models into /work/earshot/.cache/hf
.venv/bin/python -m earshot doctor --fetch
.venv/bin/python -m earshot doctor --load
