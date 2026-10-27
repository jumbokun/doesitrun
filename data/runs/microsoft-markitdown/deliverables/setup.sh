#!/usr/bin/env bash
set -euo pipefail
cd /work
if [ ! -d markitdown/.git ]; then git clone https://github.com/microsoft/markitdown /work/markitdown; fi
cd /work/markitdown
python3 -m venv .venv
.venv/bin/pip install -q --upgrade pip
.venv/bin/pip install -e 'packages/markitdown[all]'
