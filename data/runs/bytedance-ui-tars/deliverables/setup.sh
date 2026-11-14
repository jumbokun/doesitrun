#!/usr/bin/env bash
set -euo pipefail
cd /work
if [ ! -d UI-TARS/.git ]; then
  git clone https://github.com/bytedance/UI-TARS /work/UI-TARS
fi
git -C /work/UI-TARS checkout -q 582f3a7ea5d285ee8ed9e2e84048d1ab01453c49 || true
rm -rf /work/venv
uv venv --python 3.12 /work/venv
# README says `pip install ui-tars` (PyPI); install the repo's own source instead (non-editable)
uv pip install --python /work/venv/bin/python /work/UI-TARS/codes
