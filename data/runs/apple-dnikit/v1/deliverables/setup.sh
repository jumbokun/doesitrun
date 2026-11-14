#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d dnikit/.git ] || GIT_LFS_SKIP_SMUDGE=1 git clone https://github.com/apple/dnikit /work/dnikit
# Python 3.10: last version listed in the package classifiers
uv venv -p 3.10 --allow-existing /work/venv
. /work/venv/bin/activate
uv pip install -e "/work/dnikit/src/dnikit[test]" "pytest<8"
