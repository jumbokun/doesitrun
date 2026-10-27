#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d harness2/.git ] || git clone https://github.com/google-research/harness2 /work/harness2
cd /work/harness2
[ -x .venv/bin/python ] || uv venv --python 3.12 .venv
. .venv/bin/activate
uv pip install -e '.[render]'
