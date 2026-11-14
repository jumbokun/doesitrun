#!/usr/bin/env bash
# Start llama-server (docs/llama_cpp.md section 4.1, base model only) and wait until ready.
set -euo pipefail
M=/work/llama.cpp/HunyuanOCR
BIN=/work/llama.cpp/build/bin/llama-server
if curl -sf http://127.0.0.1:8080/health >/dev/null 2>&1; then echo "already running"; exit 0; fi
nohup "$BIN" \
    --model  "$M/hyocr-f16.gguf" \
    --mmproj "$M/mmproj-hyocr-f16.gguf" \
    --host 0.0.0.0 --port 8080 --alias HYVL \
    --ctx-size 10240 --n-predict 4096 \
    -fa on --jinja > /work/server.log 2>&1 &
PID=$!
echo $PID > /work/server.pid
for i in $(seq 1 600); do
  if ! kill -0 $PID 2>/dev/null; then echo "server died"; tail -50 /work/server.log; exit 1; fi
  if curl -sf http://127.0.0.1:8080/health >/dev/null 2>&1; then echo "server ready (pid $PID)"; exit 0; fi
  sleep 1
done
echo "timeout"; exit 1
