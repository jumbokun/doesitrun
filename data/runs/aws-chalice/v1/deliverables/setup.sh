#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d /work/chalice/.git ] || git clone https://github.com/aws/chalice /work/chalice
[ -x /work/.venv/bin/python ] || python3 -m venv /work/.venv
/work/.venv/bin/python -m pip install --upgrade pip
/work/.venv/bin/python -m pip install /work/chalice
/work/.venv/bin/chalice --version
