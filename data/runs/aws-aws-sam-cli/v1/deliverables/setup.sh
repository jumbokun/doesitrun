#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d aws-sam-cli/.git ] || git clone https://github.com/aws/aws-sam-cli /work/aws-sam-cli
cd /work/aws-sam-cli
python3 -m venv .venv
. .venv/bin/activate
pip install --upgrade pip
# Equivalent of `make init` minus dev/test extras; provides `sam` (and `samdev`) entry points
pip install -e .
sam --version
