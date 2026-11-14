#!/usr/bin/env bash
set -euo pipefail
source /work/env.sh
mkdir -p "$OLLAMA_MODELS"
if ! curl -sf http://127.0.0.1:11434/api/version >/dev/null; then
  nohup ollama serve > /work/server.log 2>&1 &
fi
for i in $(seq 1 120); do
  curl -sf http://127.0.0.1:11434/api/version >/dev/null && break
  sleep 1
done
curl -sf http://127.0.0.1:11434/api/version >/dev/null || { echo "server failed to start"; tail -50 /work/server.log; exit 1; }
if ! ollama list | grep -q '^gpt-oss:20b'; then
  ollama pull gpt-oss:20b
fi
# Warm up: load the model into memory so the first real request is fast.
curl -sf --max-time 1800 http://127.0.0.1:11434/api/generate \
  -d '{"model":"gpt-oss:20b","prompt":"","keep_alive":-1}' >/dev/null
echo "Ollama server ready with gpt-oss:20b"
