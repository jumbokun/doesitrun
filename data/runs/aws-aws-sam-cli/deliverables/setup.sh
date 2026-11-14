#!/usr/bin/env bash
set -euo pipefail
cd /work
export DEBIAN_FRONTEND=noninteractive
# venv module may be missing on minimal images
python3 -c 'import ensurepip, venv' 2>/dev/null || { apt-get update && apt-get install -y python3-venv; }
[ -d aws-sam-cli/.git ] || git clone --depth 1 https://github.com/aws/aws-sam-cli /work/aws-sam-cli
cd /work/aws-sam-cli
[ -x .venv/bin/python ] || python3 -m venv .venv
.venv/bin/pip install -U pip
.venv/bin/pip install -e .
.venv/bin/sam --version
