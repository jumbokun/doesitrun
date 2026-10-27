#!/usr/bin/env bash
# Start Ollama in the background and block until it serves gemma2:2b.
set -uo pipefail
export OLLAMA_HOST=127.0.0.1:11434
if ! curl -fsS http://localhost:11434/api/version >/dev/null 2>&1; then
  nohup ollama serve >> /work/server.log 2>&1 &
fi
for i in $(seq 1 120); do
  curl -fsS http://localhost:11434/api/version >/dev/null 2>&1 && break
  sleep 1
done
curl -fsS http://localhost:11434/api/version >/dev/null || { echo "ollama did not start"; exit 1; }
# Ensure the model is present (pull if missing), then warm it up
if ! curl -fsS http://localhost:11434/api/tags | grep -q '"gemma2:2b"'; then
  ollama pull gemma2:2b || exit 1
fi
curl -fsS http://localhost:11434/api/generate -d '{"model":"gemma2:2b","prompt":"hi","stream":false,"options":{"num_predict":1}}' >/dev/null || exit 1
echo "ollama ready"
exit 0
