#!/usr/bin/env bash
set -euo pipefail
cd /work
GO_VERSION=1.23.12
if [ ! -x /usr/local/go/bin/go ]; then
  curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tgz
  rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tgz && rm /tmp/go.tgz
fi
export PATH=/usr/local/go/bin:$PATH
[ -d AI-Infra-Guard/.git ] || git clone --depth 1 https://github.com/Tencent/AI-Infra-Guard
[ -d venv ] || uv venv --python 3.12 venv
. venv/bin/activate
uv pip install build setuptools wheel pip
cd AI-Infra-Guard
# README path: build the wheel locally (bundles Go binary + data/ rules), then install it
python scripts/publish_pypi.py build infra
uv pip install --reinstall infra-scan/dist/aig_infra_scan-*.whl
