#!/usr/bin/env bash
# Reproduce the Qwen-Agent + Ollama (CPU) setup from scratch. Run as root.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work

# System packages: zstd is required by the Ollama installer to extract its tarball.
apt-get update -q
apt-get install -y -q zstd ca-certificates curl git

# Clone
if [ ! -d /work/Qwen-Agent/.git ]; then
  git clone https://github.com/QwenLM/Qwen-Agent /work/Qwen-Agent
fi

# Python env + README install (editable, all extras)
if [ ! -x /work/venv/bin/python ]; then
  uv venv -p 3.12 /work/venv
fi
. /work/venv/bin/activate
cd /work/Qwen-Agent
uv pip install -e ./"[gui,rag,code_interpreter,mcp]"
# qwen_agent/utils/utils.py imports soundfile unconditionally, but setup.py does not declare it
uv pip install soundfile
cd /work

# Ollama
if ! command -v ollama >/dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | sh
fi

# Pull the model (start a temporary server if none is running)
STARTED=0
if ! curl -sf http://localhost:11434/api/version >/dev/null; then
  nohup ollama serve > /work/ollama_setup.log 2>&1 &
  OLLAMA_PID=$!; STARTED=1
  for i in $(seq 1 60); do curl -sf http://localhost:11434/api/version >/dev/null && break; sleep 1; done
fi
ollama pull qwen3:1.7b || ollama pull qwen2.5:1.5b
if [ "$STARTED" = 1 ]; then kill "$OLLAMA_PID" || true; wait "$OLLAMA_PID" 2>/dev/null || true; fi
echo "setup complete"
