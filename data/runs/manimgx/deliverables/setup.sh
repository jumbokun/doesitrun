#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d /work/manimgx/.git ] || git clone https://github.com/academa-labs/manimgx /work/manimgx
# README requires Python 3.13+; the image ships 3.12, so let uv provision 3.13.
uv python install 3.13
[ -x /work/venv/bin/python ] || uv venv -p 3.13 /work/venv
# Documented path: pip install manimgx (PyPI wheel 0.1.1 == repo version; bundles wgpu/lavapipe, fonts, encoder)
uv pip install --python /work/venv/bin/python manimgx
