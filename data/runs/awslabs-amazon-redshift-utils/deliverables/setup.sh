#!/bin/bash
set -euo pipefail
cd /work
[ -d amazon-redshift-utils ] || git clone https://github.com/awslabs/amazon-redshift-utils
uv venv --clear -p python3 /work/venv
uv pip install -p /work/venv/bin/python -r /work/amazon-redshift-utils/src/ManifestGenerator/requirements.txt
chmod +x /work/amazon-redshift-utils/src/ManifestGenerator/manifestgen.py
