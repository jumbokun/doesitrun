#!/usr/bin/env bash
set -euo pipefail
cd /work
if [ ! -d /work/aws-cli/.git ]; then
  git clone --depth 1 --branch v2 https://github.com/aws/aws-cli /work/aws-cli
fi
if [ ! -x /work/venv/bin/python ]; then
  python3 -m venv /work/venv || { rm -rf /work/venv; uv venv --seed --python python3 /work/venv; }
fi
source /work/venv/bin/activate
cd /work/aws-cli
python -m pip install -r requirements-dev-lock.txt
python -m pip install -e .
./scripts/gen-ac-index --include-builtin-index || echo "WARN: ac index generation failed (optional)"
aws --version
