#!/bin/bash
# Starts the local ClusterFuzz server in the background and waits until it serves pages.
[ -n "$VIRTUAL_ENV" ] || source /work/env.sh
cd /work/clusterfuzz
# Stop any previous instance (butler only kills the emulators itself).
pkill -f "[b]utler.py run_server" || true
pkill -f "[g]unicorn -b" || true
pkill -f "[e]xe/gcs -storage-path" || true
sleep 2
nohup python butler.py run_server --bootstrap > /work/server.log 2>&1 &
echo $! > /work/server.pid
for i in $(seq 1 180); do
  if curl -sf -o /dev/null http://localhost:9000/ && curl -sf -o /dev/null http://localhost:9000/login; then
    echo "ClusterFuzz server ready at http://localhost:9000"
    exit 0
  fi
  if ! kill -0 "$(cat /work/server.pid)" 2>/dev/null; then
    echo "server exited; see /work/server.log" >&2
    tail -30 /work/server.log >&2
    exit 1
  fi
  sleep 5
done
echo "timed out waiting for server" >&2
exit 1
