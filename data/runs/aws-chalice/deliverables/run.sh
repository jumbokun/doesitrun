#!/bin/bash
set -euo pipefail
[ -n "${VIRTUAL_ENV:-}" ] || . /work/env.sh
cd /work
[ -f /work/helloworld/app.py ] || chalice new-project helloworld
cd /work/helloworld
if ! curl -sf http://127.0.0.1:8000/ >/dev/null; then
  nohup chalice local --host 127.0.0.1 --port 8000 > /work/server.log 2>&1 &
fi
for i in $(seq 1 60); do
  curl -sf http://127.0.0.1:8000/ >/dev/null && { echo ready; exit 0; }
  sleep 1
done
echo "server failed to start"; cat /work/server.log; exit 1
