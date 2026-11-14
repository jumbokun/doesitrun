#!/usr/bin/env bash
# Start Data Formulator in the background and wait until it answers.
[ -n "${VIRTUAL_ENV:-}" ] || source /work/env.sh
mkdir -p "${DATA_FORMULATOR_HOME:-/work/df_home}"
cd /work
BROWSER=true nohup python -m data_formulator --port 5567 > /work/server.log 2>&1 &
echo $! > /work/server.pid
for i in $(seq 1 180); do
  if curl -sf http://127.0.0.1:5567/api/app-config >/dev/null && curl -sf http://127.0.0.1:5567/ >/dev/null; then
    echo "Data Formulator ready on http://127.0.0.1:5567"; exit 0
  fi
  if ! kill -0 "$(cat /work/server.pid)" 2>/dev/null; then echo "server died"; tail -50 /work/server.log; exit 1; fi
  sleep 1
done
echo "timeout"; tail -50 /work/server.log; exit 1
