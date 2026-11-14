#!/usr/bin/env bash
set -euo pipefail
export PATH="/work/llama.cpp/build/bin:$PATH"
export LD_LIBRARY_PATH="/work/llama.cpp/build/bin:${LD_LIBRARY_PATH:-}"
if curl -sf http://localhost:8080/health >/dev/null 2>&1; then echo ready; exit 0; fi
nohup llama-server --model /work/models/qwen2.5-0.5b-instruct-q4_0.gguf \
  --ctx-size 4096 --host 0.0.0.0 --port 8080 > /work/server.log 2>&1 &
PID=$!
for i in $(seq 1 300); do
  if curl -sf http://localhost:8080/health >/dev/null 2>&1; then echo ready; exit 0; fi
  kill -0 $PID 2>/dev/null || { echo "server died"; tail -50 /work/server.log; exit 1; }
  sleep 1
done
echo "timeout"; tail -50 /work/server.log; exit 1
