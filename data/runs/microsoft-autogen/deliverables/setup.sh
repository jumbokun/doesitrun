#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d /work/autogen/.git ] || git clone --depth 1 https://github.com/microsoft/autogen /work/autogen
[ -x /work/venv/bin/python ] || uv venv --seed --python 3.12 /work/venv
source /work/venv/bin/activate
uv pip install -U "autogen-agentchat" "autogen-ext[openai]"
python -c "import autogen_core, autogen_agentchat, autogen_ext; print('ok')"
