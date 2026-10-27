#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d data-formulator/.git ] || git clone https://github.com/microsoft/data-formulator /work/data-formulator
# README: `pip install data_formulator` (0.8.0b1 preview matches repo HEAD; wheel ships the built frontend)
[ -x /work/venv/bin/python ] || uv venv -p 3.12 /work/venv
uv pip install --python /work/venv/bin/python --pre "data_formulator==0.8.0b1"
