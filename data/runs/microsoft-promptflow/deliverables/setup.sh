#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d promptflow/.git ] || git clone https://github.com/microsoft/promptflow /work/promptflow
[ -x venv/bin/python ] || uv venv -p 3.12 /work/venv
VIRTUAL_ENV=/work/venv uv pip install --python /work/venv/bin/python promptflow==1.18.5 promptflow-tools==1.6.1
/work/venv/bin/pf --version
