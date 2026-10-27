#!/usr/bin/env bash
# Start the decision server on 127.0.0.1:8765 in the background and block until
# it answers.  Expects /work/env.sh to have been sourced; sources it otherwise.
set -euo pipefail

HOST=127.0.0.1
PORT=8765
LOG=/work/server.log
NANOJEV_HOME="${NANOJEV_HOME:-/work/NanoJev}"

if [ -z "${VIRTUAL_ENV:-}" ]; then
  # shellcheck disable=SC1091
  . /work/env.sh
fi

# A stale server from an earlier run would hold the port and the GPU, so stop
# it first.  Only matching python processes are touched, never this shell.
stale_pids() {
  pgrep -f 'python.*scripts/serve_decisions\.py' 2>/dev/null \
    | grep -v -x -e "$$" -e "${PPID:-0}" || true
}
for pid in $(stale_pids); do
  echo "[run] stopping stale server pid $pid"
  kill "$pid" 2>/dev/null || true
done
for _ in $(seq 1 30); do
  [ -z "$(stale_pids)" ] && break
  sleep 0.5
done
for pid in $(stale_pids); do kill -9 "$pid" 2>/dev/null || true; done

cd "$NANOJEV_HOME"
nohup python scripts/serve_decisions.py \
  --checkpoint-dir checkpoints/NanoJev-unified \
  --web-root web \
  --host "$HOST" --port "$PORT" \
  --disable-native-triton \
  > "$LOG" 2>&1 &
SERVER_PID=$!
echo "[run] serve_decisions.py pid $SERVER_PID, log $LOG"

# Loading the fp32 0.6B backbone onto the GPU takes ~1.5 min on this machine.
DEADLINE=$(( $(date +%s) + 900 ))
while :; do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "[run] server exited during startup; last log lines:" >&2
    tail -n 40 "$LOG" >&2
    exit 1
  fi
  if curl -fsS -m 5 "http://$HOST:$PORT/api/health" >/dev/null 2>&1; then
    echo "[run] ready: $(curl -fsS -m 5 "http://$HOST:$PORT/api/health")"
    exit 0
  fi
  if [ "$(date +%s)" -ge "$DEADLINE" ]; then
    echo "[run] timed out waiting for http://$HOST:$PORT/api/health" >&2
    tail -n 40 "$LOG" >&2
    exit 1
  fi
  sleep 2
done
