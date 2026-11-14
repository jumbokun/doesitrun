#!/usr/bin/env bash
set -euxo pipefail
cd /work
[ -d tiktoken/.git ] || git clone https://github.com/openai/tiktoken /work/tiktoken
# Rust toolchain (needed to build the extension from source; not in base image)
if ! command -v cargo >/dev/null && [ ! -x "$HOME/.cargo/bin/cargo" ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
fi
export PATH="$HOME/.cargo/bin:$PATH"
[ -d /work/venv ] || uv venv /work/venv --python 3.12
. /work/venv/bin/activate
uv pip install pip
uv pip install /work/tiktoken pytest hypothesis
# pre-download vocab files into a persistent cache
export TIKTOKEN_CACHE_DIR=/work/tiktoken_cache
mkdir -p "$TIKTOKEN_CACHE_DIR"
cd /tmp && python -c "
import tiktoken
for n in ['gpt2','r50k_base','p50k_base','p50k_edit','cl100k_base','o200k_base','o200k_harmony']:
    try: tiktoken.get_encoding(n)
    except Exception as e: print('skip', n, e)
"
