#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
[ -d /work/gpt-oss/.git ] || git clone --depth 1 https://github.com/openai/gpt-oss /work/gpt-oss
apt-get update -qq
apt-get install -y -qq zstd pciutils curl ca-certificates
if ! command -v ollama >/dev/null; then
  curl -fsSL https://ollama.com/install.sh | sh
fi
source /work/env.sh
mkdir -p "$OLLAMA_MODELS"
nohup ollama serve > /work/setup-ollama.log 2>&1 &
PID=$!
for i in $(seq 1 120); do curl -sf http://127.0.0.1:11434/api/version >/dev/null && break; sleep 1; done
ollama pull gpt-oss:20b
kill $PID || true; wait $PID 2>/dev/null || true
echo "setup complete"
