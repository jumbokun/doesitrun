#!/usr/bin/env bash
set -euo pipefail
NODE_VERSION=24.15.0
PNPM_VERSION=11.21.0
PYRIGHT_COMMIT=611afe615b8659a154aa9656ee5b8cfddf57cdac
cd /work
# Node.js (official binary tarball; docs say 16.x but CI uses 24.x and deps need modern node)
if [ ! -x /work/node/bin/node ]; then
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/node.tar.xz
  mkdir -p /work/node
  tar -xJf /tmp/node.tar.xz -C /work/node --strip-components=1
  rm -f /tmp/node.tar.xz
fi
export PATH=/work/node/bin:$PATH
# pnpm (version pinned by packageManager field)
npm install -g "pnpm@${PNPM_VERSION}"
# Clone
if [ ! -d /work/pyright/.git ]; then
  git clone https://github.com/microsoft/pyright /work/pyright
  git -C /work/pyright checkout "$PYRIGHT_COMMIT" || true
fi
cd /work/pyright
export CI=true
pnpm run install:all
cd packages/pyright
pnpm run build
