#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d mcp/.git ] || git clone --depth 1 https://github.com/awslabs/mcp /work/mcp
cd /work/mcp/src/aws-documentation-mcp-server
uv python install 3.13
uv venv --python 3.13 --allow-existing /work/venv
UV_PROJECT_ENVIRONMENT=/work/venv uv sync --frozen --no-dev
