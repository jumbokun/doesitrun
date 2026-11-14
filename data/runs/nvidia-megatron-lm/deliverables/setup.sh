#!/usr/bin/env bash
set -euxo pipefail
cd /work
if [ ! -d /work/Megatron-LM/.git ]; then
  git clone https://github.com/NVIDIA/Megatron-LM /work/Megatron-LM
fi
cd /work/Megatron-LM
git checkout 05c4a8ba04e2d3422f56ffdda7ff2059da431e18
uv venv --clear --python 3.12 /work/venv
export VIRTUAL_ENV=/work/venv PATH=/work/venv/bin:$PATH
PY=/work/venv/bin/python
PKGS=("torch==2.15.0+cpu" "triton==3.9.0" "transformers==5.23.0" "numpy" "packaging>=24.2")
# CPU-only torch from the PyTorch CPU index; triton is imported unconditionally by megatron.core
# Run from /work with --no-config: the repo's pyproject [tool.uv] override-dependencies
# ("torch; sys_platform == 'never'", same for triton) silently drop torch/triton otherwise.
install_deps() {
  (cd /work && uv pip install --no-config --python $PY "$@" --index-url https://pypi.org/simple \
      --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match \
      "${PKGS[@]}")
}
install_deps
# Documented step (README): install from source
uv pip install --python $PY -e .
$PY -c "import torch, triton, transformers, numpy, megatron.core.datasets.indexed_dataset"
# GPT-2 tokenizer files
mkdir -p /work/gpt2
for f in config.json tokenizer.json tokenizer_config.json vocab.json merges.txt; do
  curl -fsSL --retry 5 -o /work/gpt2/$f https://huggingface.co/openai-community/gpt2/resolve/main/$f
done
