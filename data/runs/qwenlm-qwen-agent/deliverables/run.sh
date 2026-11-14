#!/usr/bin/env bash
# Start Ollama (OpenAI-compatible API at http://localhost:11434/v1) and block until the model answers.
set -euo pipefail
MODEL=${MODEL:-qwen3:1.7b}
export OLLAMA_HOST=${OLLAMA_HOST:-127.0.0.1:11434}
export OLLAMA_KEEP_ALIVE=${OLLAMA_KEEP_ALIVE:--1}

if ! curl -sf http://localhost:11434/api/version >/dev/null; then
  nohup ollama serve >> /work/server.log 2>&1 &
fi
for i in $(seq 1 120); do
  curl -sf http://localhost:11434/api/version >/dev/null && break
  sleep 1
done
curl -sf http://localhost:11434/api/version >/dev/null || { echo "ollama did not start"; exit 1; }

if ! ollama list | awk '{print $1}' | grep -qx "$MODEL"; then
  ollama pull "$MODEL" || { MODEL=qwen2.5:1.5b; ollama pull "$MODEL"; }
fi

# Warm up: load model into memory and wait for a real completion via the OpenAI endpoint.
for i in $(seq 1 60); do
  if curl -sf --max-time 300 http://localhost:11434/v1/chat/completions \
      -H 'Content-Type: application/json' -H 'Authorization: Bearer EMPTY' \
      -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Say OK /no_think\"}],\"max_tokens\":16}" >/dev/null; then
    echo "server ready (model $MODEL)"
    exit 0
  fi
  sleep 2
done
echo "model did not become ready"; exit 1
