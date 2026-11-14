#!/usr/bin/env bash
# Reproduce Qwen-MM-Plugins core MCP server setup (CPU, native mode, no API key).
set -euo pipefail
cd /work
if [ ! -d Qwen-MM-Plugins/.git ]; then
  git clone https://github.com/QwenLM/Qwen-MM-Plugins /work/Qwen-MM-Plugins
fi
cd /work/Qwen-MM-Plugins
git checkout -q eea016154bf6e85a9a2d45331e7ae4e786a412c1 || true   # commit tested on 2026-11-13
# Documented "fast source loop": venv + editable install of the core profile (= viz extras)
if [ ! -x /work/venv/bin/python ]; then
  python3 -m venv /work/venv || { rm -rf /work/venv; uv venv --seed -p python3 /work/venv; }
fi
/work/venv/bin/python -m pip install --upgrade pip
/work/venv/bin/python -m pip install -e '.[core]'
/work/venv/bin/python -c "import pypdfium2, pandas, matplotlib, PIL, mcp; print('deps ok')"
