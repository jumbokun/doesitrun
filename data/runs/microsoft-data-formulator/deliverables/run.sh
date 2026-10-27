#!/usr/bin/env bash
set -u
source /work/env.sh
if curl -sf http://127.0.0.1:5567/ >/dev/null 2>&1; then exit 0; fi
cd /work
nohup python -m data_formulator --port 5567 --dev > /work/server.log 2>&1 &
for i in $(seq 1 180); do
  if curl -sf http://127.0.0.1:5567/ >/dev/null 2>&1 && curl -sf http://127.0.0.1:5567/api/app-config >/dev/null 2>&1; then
    echo "Data Formulator ready on :5567"; exit 0
  fi
  sleep 1
done
echo "server failed to start"; tail -50 /work/server.log; exit 1
