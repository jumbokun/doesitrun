#!/usr/bin/env bash
# Reproducible CPU setup for Tencent/MedicalNet `python train.py --ci_test`
set -euo pipefail
cd /work
if [ ! -d MedicalNet/.git ]; then
  git clone https://github.com/Tencent/MedicalNet /work/MedicalNet
fi
# README asks for Python 3.7 + numpy==1.15.4/scipy==1.1.0/nibabel==2.4.1 but also torch>=2.6.0,
# which is unsatisfiable. Use Python 3.11 with CPU torch and compatible pins.
uv venv -q --allow-existing -p 3.11 /work/venv
VIRTUAL_ENV=/work/venv uv pip install \
  --index-url https://download.pytorch.org/whl/cpu \
  --extra-index-url https://pypi.org/simple \
  --index-strategy unsafe-best-match \
  "torch==2.6.0" "numpy==1.26.4" "scipy==1.13.1" "nibabel==4.0.2"
echo "setup complete"
