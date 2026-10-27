#!/usr/bin/env bash
set -uo pipefail
PROJECT_DIR=/work/adk-recipes/core/python/ambient-expense-agent
cd "$PROJECT_DIR"
export GOOGLE_API_KEY="${GOOGLE_API_KEY:-dummy}"
export MODEL_NAME="${MODEL_NAME:-gemini-3.5-flash}"
PY="$PROJECT_DIR/.venv/bin/python"
if curl -sf http://localhost:8080/list-apps >/dev/null 2>&1; then exit 0; fi
nohup "$PY" expense_agent/fast_api_app.py > /work/server.log 2>&1 &
PID=$!
for i in $(seq 1 120); do
  if curl -sf http://localhost:8080/list-apps | grep -q expense_agent; then
    echo "server ready (pid $PID)"; exit 0
  fi
  kill -0 $PID 2>/dev/null || { echo "server died"; tail -50 /work/server.log; exit 1; }
  sleep 1
done
echo "timeout"; tail -50 /work/server.log; exit 1
