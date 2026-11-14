#!/usr/bin/env bash
set -euo pipefail
[ -n "${VIRTUAL_ENV:-}" ] || source /work/env.sh
cd /work
[ -f /work/helloworld/app.py ] || chalice new-project helloworld
cd /work/helloworld
nohup chalice local --host 127.0.0.1 --port 8000 > /work/server.log 2>&1 &
for i in $(seq 1 60); do
  if curl -sf http://127.0.0.1:8000/ >/dev/null; then echo "server ready"; exit 0; fi
  sleep 1
done
echo "server failed to start"; cat /work/server.log; exit 1
