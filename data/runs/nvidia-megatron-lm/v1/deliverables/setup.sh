#!/usr/bin/env bash
# Reproducible CPU-only setup of Megatron-LM for tools/preprocess_data.py
set -euo pipefail
cd /work

REPO_DIR=/work/Megatron-LM
COMMIT=19895dafba387fe4807d433809fbdeeb801bf7f6   # commit tested
VENV=/work/venv
TOK_DIR=/work/gpt2

# 1. Clone
if [ ! -d "$REPO_DIR/.git" ]; then
  git clone https://github.com/NVIDIA/Megatron-LM "$REPO_DIR"
fi
git -C "$REPO_DIR" fetch --depth 1 origin "$COMMIT" 2>/dev/null || true
git -C "$REPO_DIR" checkout -q "$COMMIT" || echo "WARN: could not checkout $COMMIT, using current HEAD"

# 2. Python env (README: uv pip install -e .)
[ -x "$VENV/bin/python" ] || uv venv "$VENV" --python 3.12
. "$VENV/bin/activate"
# CPU-only torch (avoid pulling multi-GB CUDA wheels)
uv pip install torch --index-url https://download.pytorch.org/whl/cpu
# Megatron-core from source, as documented
uv pip install -e "$REPO_DIR"
# Undocumented runtime deps:
#  - triton: imported unconditionally by megatron/core/transformer/moe/ops/paged_stash.py
#  - transformers: needed by HuggingFaceTokenizer; <5 because 5.x loads the GPT-2
#    tokenizer with eos_token=None, so --append-eod writes None and crashes.
uv pip install "triton" "transformers>=4.40,<5"

# 3. GPT-2 tokenizer files (public, no token needed)
mkdir -p "$TOK_DIR"
for f in tokenizer.json tokenizer_config.json vocab.json merges.txt; do
  [ -s "$TOK_DIR/$f" ] || curl -fsSL --retry 5 -o "$TOK_DIR/$f" \
    "https://huggingface.co/openai-community/gpt2/resolve/main/$f"
done

python -c "import megatron.core, transformers, triton; print('setup OK')"
