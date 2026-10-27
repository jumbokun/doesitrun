#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d cascadia-code/.git ] || git clone https://github.com/microsoft/cascadia-code /work/cascadia-code
# requirements.txt was pip-compiled with Python 3.11; use a 3.11 venv via uv
uv venv --allow-existing -p 3.11 /work/venv
. /work/venv/bin/activate
uv pip install -r /work/cascadia-code/requirements.txt
# fs (pyfilesystem2) needs pkg_resources, which is no longer preinstalled / was removed in setuptools>=81
uv pip install "setuptools<81"
cd /work/cascadia-code
python build.py -P -NF -M -I
ls -l build/ttf/CascadiaCode.ttf
