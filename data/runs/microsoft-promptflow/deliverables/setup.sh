#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d promptflow/.git ] || git clone --depth 1 https://github.com/microsoft/promptflow /work/promptflow
[ -x .venv/bin/python ] || uv venv -p 3.12 /work/.venv
uv pip install -p /work/.venv/bin/python promptflow==1.18.5 promptflow-tools==1.6.1
# install flow's own requirements (promptflow, promptflow-tools; already satisfied)
uv pip install -p /work/.venv/bin/python -r /work/promptflow/examples/flows/standard/conditional-flow-for-if-else/requirements.txt
/work/.venv/bin/pf --version
