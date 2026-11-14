#!/bin/bash
set -euo pipefail
cd /work
[ -d chalice/.git ] || git clone https://github.com/aws/chalice /work/chalice
[ -x /work/.venv/bin/python ] || python3 -m venv /work/.venv
/work/.venv/bin/python -m pip install --upgrade "pip<26.3"
/work/.venv/bin/python -m pip install -e /work/chalice
