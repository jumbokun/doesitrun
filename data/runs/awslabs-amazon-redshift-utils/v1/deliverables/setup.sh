#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d amazon-redshift-utils ] || git clone https://github.com/awslabs/amazon-redshift-utils
uv venv --python 3.12 /work/venv
uv pip install --python /work/venv/bin/python -r /work/amazon-redshift-utils/src/ManifestGenerator/requirements.txt
# Script is committed without the executable bit
chmod +x /work/amazon-redshift-utils/src/ManifestGenerator/manifestgen.py
