#!/usr/bin/env bash
set -euxo pipefail
cd /work
[ -d Megatron-LM ] || git clone --depth 1 https://github.com/NVIDIA/Megatron-LM /work/Megatron-LM
cd /work/Megatron-LM
[ -d .venv ] || uv venv --python 3.12 .venv
source .venv/bin/activate
# CPU-only torch to avoid pulling CUDA wheels
# pyproject [tool.uv] override-dependencies disables torch installs (expects NGC PyTorch image);
# use --no-config so the CPU wheel is actually installed.
uv pip install --no-config --python .venv/bin/python --index-url https://download.pytorch.org/whl/cpu "torch>=2.6.0"
uv pip install -e .
# megatron/core/transformer/moe/ops/paged_stash.py imports triton unconditionally (also blocked by the override)
uv pip install --no-config --python .venv/bin/python triton
uv pip install transformers tokenizers sentencepiece tiktoken nltk
# GPT-2 tokenizer files
mkdir -p /work/gpt2
for f in config.json tokenizer.json tokenizer_config.json vocab.json merges.txt; do
  [ -s /work/gpt2/$f ] || curl -fsSL -o /work/gpt2/$f https://huggingface.co/openai-community/gpt2/resolve/main/$f
done
ln -sfn /work/Megatron-LM/tools /work/tools
