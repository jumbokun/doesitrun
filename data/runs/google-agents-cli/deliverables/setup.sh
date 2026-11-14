#!/usr/bin/env bash
set -euo pipefail
cd /work
if [ ! -d /work/agents-cli/.git ]; then
  git clone https://github.com/google/agents-cli /work/agents-cli
fi
git -C /work/agents-cli checkout -q 6eedbdc2f44c388cbfc5f305eb83b9924cfefebb
[ -x /work/venv/bin/python ] || uv venv --python 3.12 /work/venv
uv pip install -p /work/venv/bin/python /work/agents-cli
/work/venv/bin/agents-cli --version || /work/venv/bin/agents-cli --help >/dev/null
