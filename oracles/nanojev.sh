# Pass: NanoJev decision server on :8765 is healthy and /api/evaluate returns 200 with a decision,
# using GPU (memory rose by >300 MiB).
set -e
source /oracle/gpu_delta.sh
before=$(gpu_used)
source /work/env.sh
timeout 1500 bash /work/run.sh
after=$(gpu_used); echo "ORACLE: gpu MiB before=$before after=$after"
curl -sf --max-time 30 localhost:8765/api/health
code=$(curl -s -o /tmp/nj.json -w '%{http_code}' --max-time 300 localhost:8765/api/evaluate \
  -H 'content-type: application/json' \
  -d '{"states":[{"id":"s1","state":"An enemy is directly ahead, centered in the crosshair.","questions":{"fire":{"type":"boolean","instructions":"Should the agent fire now?"}}}]}')
echo "ORACLE: http=$code body=$(head -c 2000 /tmp/nj.json)"
test "$code" = 200
grep -q '"s1"' /tmp/nj.json
test $((after - before)) -gt 300 || { echo "ORACLE: GPU memory did not rise"; exit 1; }
echo "ORACLE PASS"
