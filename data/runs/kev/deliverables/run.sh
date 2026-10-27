#!/usr/bin/env bash
# Start the Kev-0.8B server on the GPU in the background and block until it can
# answer a /v1/systemone request. Run after `source /work/env.sh`.
set -uo pipefail

REPO_DIR=${KEV_REPO:-/work/kev}
RUN_SPEC=${KEV_RUN:-jaredpalmer/kev-0.8b}
PORT=${KEV_PORT:-8009}
LOG=/work/server.log
READY_TIMEOUT=${KEV_READY_TIMEOUT:-1200}

export HF_HOME=${HF_HOME:-/work/hf-cache}
export HF_HUB_DISABLE_PROGRESS_BARS=1
export TOKENIZERS_PARALLELISM=false

PY="$REPO_DIR/.venv/bin/python"
[ -x "$PY" ] || { echo "run.sh: $PY missing; run /work/setup.sh first" >&2; exit 1; }

probe() {
    # Ready means the real endpoint answers, not just that the port is open:
    # weight loading and the first CUDA-graph capture both happen before this
    # returns 200.
    curl -fsS --max-time 180 "localhost:$PORT/v1/systemone" \
        -H 'content-type: application/json' \
        -d '{"state":"ready?","model":"kev-latest",
             "questions":{"ok":{"type":"noul","instructions":"Is this a probe?"}}}' \
        >/dev/null 2>&1
}

if probe; then
    echo "run.sh: a Kev server is already answering on port $PORT"
    exit 0
fi

cd "$REPO_DIR"
# --device cuda fails closed: no silent CPU fallback.
nohup "$PY" -m kev.serve --run "$RUN_SPEC" --port "$PORT" --device cuda \
    >>"$LOG" 2>&1 &
SERVER_PID=$!
echo "run.sh: started kev.serve pid=$SERVER_PID run=$RUN_SPEC port=$PORT log=$LOG"

deadline=$(( $(date +%s) + READY_TIMEOUT ))
while :; do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "run.sh: server process exited before becoming ready; last log lines:" >&2
        tail -n 40 "$LOG" >&2
        exit 1
    fi
    if probe; then
        echo "run.sh: ready on http://localhost:$PORT/v1/systemone"
        nvidia-smi --query-gpu=memory.used --format=csv,noheader 2>/dev/null \
            | sed 's/^/run.sh: GPU memory in use: /'
        exit 0
    fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
        echo "run.sh: not ready after ${READY_TIMEOUT}s; last log lines:" >&2
        tail -n 40 "$LOG" >&2
        exit 1
    fi
    sleep 2
done
