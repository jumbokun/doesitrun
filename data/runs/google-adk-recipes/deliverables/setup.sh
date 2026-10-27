#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d adk-recipes/.git ] || git clone https://github.com/google/adk-recipes.git adk-recipes
cd adk-recipes/core/python/ambient-expense-agent
uv sync --python 3.12
# placeholder creds: under-$100 path never calls the LLM
cat > .env <<'ENV'
GOOGLE_API_KEY=dummy
MODEL_NAME=gemini-3.5-flash
ENV
