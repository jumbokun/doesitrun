#!/bin/bash
set -euo pipefail
cd /work
[ -d yapf/.git ] || git clone https://github.com/google/yapf /work/yapf
# Ubuntu 24.04 system python is "externally managed" (PEP 668); use a venv
[ -x /work/venv/bin/python ] || python3 -m venv /work/venv
/work/venv/bin/pip install -q --upgrade pip
/work/venv/bin/pip install -q /work/yapf
/work/venv/bin/yapf --version
