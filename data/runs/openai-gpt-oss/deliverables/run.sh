#!/usr/bin/env bash
set -uo pipefail
source /work/env.sh
if ! curl -sf http://127.0.0.1:11434/api/version >/dev/null; then
  nohup ollama serve > /work/server.log 2>&1 &
fi
for i in $(seq 120); do curl -sf http://127.0.0.1:11434/api/version >/dev/null && break; sleep 1; done
curl -sf http://127.0.0.1:11434/api/version >/dev/null || { echo "server failed"; exit 1; }
ollama list | grep -q 'gpt-oss:20b' || ollama pull gpt-oss:20b || exit 1
# warm-up: load model into memory so the first request is fast
for i in $(seq 3); do
  curl -sf --max-time 900 http://127.0.0.1:11434/api/generate -d '{"model":"gpt-oss:20b","prompt":"","keep_alive":"60m"}' >/dev/null && break
  sleep 5
done
echo "ollama ready"
exit 0
