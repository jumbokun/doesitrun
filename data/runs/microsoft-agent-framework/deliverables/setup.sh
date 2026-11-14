#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d agent-framework/.git ] || git clone --depth 1 https://github.com/microsoft/agent-framework /work/agent-framework
[ -x /work/venv/bin/python ] || uv venv -p python3 /work/venv
uv pip install -p /work/venv/bin/python "agent-framework==1.26.0"
