#!/usr/bin/env bash
# Reproduces the ParlAI CPU setup (README "Developer Installation") from scratch.
set -euxo pipefail
cd /work
[ -d ParlAI/.git ] || git clone https://github.com/facebookresearch/ParlAI.git ParlAI
cd ParlAI
# Python 3.12 (system) cannot install the pinned requirements (torch 2.0.0, pandas 1.4.0, scipy 1.10.0);
# use a uv-managed Python 3.10 venv instead of README's python3.8.
rm -rf venv
uv venv -p 3.10 --seed venv
venv/bin/pip install --upgrade pip wheel
# setuptools>=81 removed pkg_resources, which parlai/core/opt.py imports.
venv/bin/pip install 'setuptools<70'
# pyyaml==5.4 sdist fails with Cython 3; build it against Cython<3 without isolation.
venv/bin/pip install 'cython<3'
venv/bin/pip install --no-build-isolation pyyaml==5.4
# pyzmq==18.1.0 has no cp310 wheel and fails to compile; bump it. CPU-only torch wheels.
sed 's/^pyzmq==18.1.0/pyzmq==25.1.2/' requirements.txt > /tmp/parlai-req.txt
venv/bin/pip install -r /tmp/parlai-req.txt --extra-index-url https://download.pytorch.org/whl/cpu
# scikit-learn is imported by core torch_classifier_agent but commented out in requirements.txt.
venv/bin/pip install scikit-learn==1.3.2
venv/bin/python setup.py develop
venv/bin/pip install 'setuptools<70'
# Pre-fetch the README example datasets into the default datapath.
venv/bin/parlai display_data -t squad -n 1 >/dev/null
venv/bin/parlai display_data -t personachat -dt valid -n 1 >/dev/null
