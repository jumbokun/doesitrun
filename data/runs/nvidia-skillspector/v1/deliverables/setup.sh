#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d SkillSpector/.git ] || git clone https://github.com/NVIDIA/SkillSpector /work/SkillSpector
cd /work/SkillSpector
[ -d .venv ] || uv venv .venv --python python3
source .venv/bin/activate
make install
skillspector --help >/dev/null
