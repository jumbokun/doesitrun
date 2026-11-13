#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d mcp/.git ] || git clone --depth 1 https://github.com/awslabs/mcp /work/mcp
cd /work/mcp/src/aws-documentation-mcp-server
export UV_PROJECT_ENVIRONMENT=/work/venv
uv python install 3.12
uv sync --frozen --no-dev --python 3.12
