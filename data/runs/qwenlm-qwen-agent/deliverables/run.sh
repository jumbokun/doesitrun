#!/usr/bin/env bash
set -u
MODEL=qwen3:1.7b
if ! curl -sf http://localhost:11434/api/tags >/dev/null; then
  nohup ollama serve >> /work/server.log 2>&1 &
fi
for i in $(seq 120); do curl -sf http://localhost:11434/api/tags >/dev/null && break; sleep 1; done
ollama list | grep -q "^$MODEL" || ollama pull $MODEL >> /work/server.log 2>&1 || { MODEL=qwen2.5:1.5b; ollama pull $MODEL >> /work/server.log 2>&1; }
# warm up: load model and wait until the OpenAI-compatible endpoint answers
for i in $(seq 120); do
  if curl -sf http://localhost:11434/v1/chat/completions -H 'Content-Type: application/json' \
     -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"hi /no_think\"}],\"max_tokens\":8}" >/dev/null; then
    echo "Ollama ready with $MODEL"; exit 0
  fi
  sleep 2
done
echo "server not ready" >&2; exit 1
