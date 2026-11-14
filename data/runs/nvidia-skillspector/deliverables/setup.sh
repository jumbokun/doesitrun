#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d SkillSpector/.git ] || git clone https://github.com/NVIDIA/SkillSpector /work/SkillSpector
cd /work/SkillSpector
[ -d .venv ] || uv venv --python python3 .venv
source .venv/bin/activate
make install
skillspector --help >/dev/null
