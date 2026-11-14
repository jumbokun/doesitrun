#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d /work/tiktoken/.git ] || git clone https://github.com/openai/tiktoken /work/tiktoken
# Rust toolchain (Cargo.toml uses edition 2024 -> needs rustc >= 1.85; not in base image)
export RUSTUP_HOME=/work/.rustup CARGO_HOME=/work/.cargo
if [ ! -x /work/.cargo/bin/cargo ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path
fi
export PATH=/work/.cargo/bin:$PATH
[ -d /work/venv ] || uv venv --python python3 /work/venv
. /work/venv/bin/activate
uv pip install pip
cd /work/tiktoken
pip install .
cd /work
# Pre-fetch vocab files into a persistent cache
export TIKTOKEN_CACHE_DIR=/work/tiktoken_cache
python -I -c "
import tiktoken
for n in ['gpt2','r50k_base','p50k_base','p50k_edit','cl100k_base','o200k_base','o200k_harmony']:
    tiktoken.get_encoding(n)
"
