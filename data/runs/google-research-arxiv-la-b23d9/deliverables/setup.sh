#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d arxiv-latex-cleaner ] || git clone https://github.com/google-research/arxiv-latex-cleaner
cd arxiv-latex-cleaner
git checkout -q 1bc61c1
uv venv --python 3.12 /work/venv
uv pip install --python /work/venv/bin/python .
