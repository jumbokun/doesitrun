#!/usr/bin/env bash
# Reproduce ParlAI CPU setup from scratch.
set -euo pipefail
cd /work
if [ ! -d ParlAI/.git ]; then
  git clone --depth 1 https://github.com/facebookresearch/ParlAI /work/ParlAI
fi
cd /work/ParlAI
# README asks for Python 3.8; uv fetches a managed interpreter (Ubuntu 24.04 ships 3.12 only)
uv venv --allow-existing -p 3.8 venv
. venv/bin/activate
uv pip install --upgrade pip setuptools wheel
# tokenizers>=0.21 (pulled by unpinned litellm) has no py3.8 wheel and its sdist fails to build
echo 'tokenizers<0.21' > /work/constraints.txt
uv pip install -r requirements.txt -c /work/constraints.txt \
  --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match
# scikit-learn is imported by parlai.core.torch_classifier_agent but commented out of requirements.txt
uv pip install "scikit-learn==1.3.2"
python setup.py develop
# warm the default datapath with SQuAD
parlai display_data -t squad -n 1 >/dev/null
