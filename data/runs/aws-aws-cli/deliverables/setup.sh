#!/usr/bin/env bash
set -euo pipefail
cd /work
if [ ! -d aws-cli/.git ]; then
  git clone --depth 1 -b v2 https://github.com/aws/aws-cli aws-cli
fi
cd aws-cli
python3 -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements-dev-lock.txt
python -m pip install -e .
