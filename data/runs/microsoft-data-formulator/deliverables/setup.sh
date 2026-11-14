#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d data-formulator ] || git clone --depth 1 https://github.com/microsoft/data-formulator /work/data-formulator
# Node.js 20 (needed to build the frontend; not in base image)
NODE_VER=v22.21.1
if [ "$(/work/node/bin/node -v 2>/dev/null)" != "$NODE_VER" ]; then
  curl -fsSL https://nodejs.org/dist/$NODE_VER/node-$NODE_VER-linux-x64.tar.xz -o /tmp/node.tar.xz
  rm -rf /work/node && mkdir -p /work/node && tar -xJf /tmp/node.tar.xz -C /work/node --strip-components=1
fi
export PATH=/work/node/bin:$PATH
npm install -g yarn@1.22.22
cd /work/data-formulator
yarn install --frozen-lockfile
yarn build
test -f py-src/data_formulator/dist/index.html
# Python env
uv venv --python 3.12 /work/venv
uv pip install --python /work/venv/bin/python -e .
# Patch: fall back to a default workspace when a client omits X-Workspace-Id
# (the bundled frontend always sends it; plain API clients may not).
F=py-src/data_formulator/workspace_factory.py
grep -q DF_DEFAULT_WORKSPACE_ID "$F" || sed -i \
  's|    return request.headers.get("X-Workspace-Id") or None|    import os\n    return request.headers.get("X-Workspace-Id") or os.environ.get("DF_DEFAULT_WORKSPACE_ID") or None|' "$F"
grep -q DF_DEFAULT_WORKSPACE_ID "$F"
