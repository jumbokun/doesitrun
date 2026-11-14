#!/bin/bash
# Starts the local ClusterFuzz server (with --bootstrap) in the background and
# blocks until the web UI on :9000 is up and the default fuzzers exist.
set -u
source /work/env.sh
cd /work/clusterfuzz

# Stop any previous instance.
pkill -f "butler.py run_server" 2>/dev/null
pkill -f "gunicorn -b" 2>/dev/null
pkill -f "emulators/gcs.go" 2>/dev/null
pkill -f "CloudDatastore.jar" 2>/dev/null
pkill -f "pubsub-emulator" 2>/dev/null
sleep 2

# Dependencies were installed by setup.sh, so skip reinstalling them each start.
nohup python butler.py run_server --bootstrap --skip-install-deps \
    > /work/server.log 2>&1 &
PID=$!

for i in $(seq 1 300); do
  if ! kill -0 $PID 2>/dev/null; then
    echo "Server process exited; see /work/server.log" >&2
    tail -30 /work/server.log >&2
    exit 1
  fi
  if curl -sf -o /dev/null http://localhost:9000/ && \
     curl -sf http://localhost:9000/fuzzers | grep -q "fuzzers: JSON.parse(atob('W3si"; then
    echo "ClusterFuzz server is ready at http://localhost:9000"
    exit 0
  fi
  sleep 2
done
echo "Timed out waiting for server" >&2
exit 1
