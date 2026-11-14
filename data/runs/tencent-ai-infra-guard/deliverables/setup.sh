#!/usr/bin/env bash
set -euo pipefail
WORK=/work
REPO=$WORK/AI-Infra-Guard
GO_VERSION=1.24.5
cd $WORK
[ -d "$REPO/.git" ] || git clone --depth 1 https://github.com/Tencent/AI-Infra-Guard "$REPO"

# Go toolchain (not in the base image; go.mod needs >= 1.23.2)
if [ ! -x $WORK/go/bin/go ]; then
  curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tgz
  tar -C $WORK -xzf /tmp/go.tgz && rm /tmp/go.tgz
fi
export PATH=$WORK/go/bin:$PATH GOPATH=$WORK/gopath GOTOOLCHAIN=local

# Build the Go scanner into the place the Python wrapper expects it
cd "$REPO"
mkdir -p infra-scan/aig_infra_scan/bin
CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -buildvcs=false \
  -o infra-scan/aig_infra_scan/bin/ai-infra-guard ./cmd/cli/main.go

# Python venv with an editable install; the wrapper then reads rules from repo data/
uv venv --python 3.12 $WORK/venv
uv pip install --python $WORK/venv/bin/python -e "$REPO/infra-scan"
echo "setup complete"
