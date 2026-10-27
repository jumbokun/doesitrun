#!/usr/bin/env bash
# Reproduce langextract + Ollama (gemma2:2b) setup from scratch. Run as root.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work

# System packages: zstd is needed by the Ollama installer (tar.zst bundles); pciutils/lshw silence GPU detection
apt-get update -y
apt-get install -y --no-install-recommends zstd pciutils lshw ca-certificates curl git

# Clone
if [ ! -d /work/langextract/.git ]; then
  git clone https://github.com/google/langextract.git /work/langextract
fi

# Python environment (venv, as suggested by README)
if [ ! -x /work/venv/bin/python ]; then
  uv venv --python 3.12 /work/venv
fi
uv pip install --python /work/venv/bin/python -e /work/langextract

# Ollama
if ! command -v ollama >/dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | sh
fi

# Pull model (needs a running server)
bash /work/run.sh
ollama pull gemma2:2b
ollama list
