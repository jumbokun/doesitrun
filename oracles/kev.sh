# Pass: local Kev server on :8009 answers the README ticket with a valid department,
# and GPU memory rose by >500 MiB after start (i.e. it runs on the local GPU, not CPU).
set -e
source /oracle/gpu_delta.sh
before=$(gpu_used)
source /work/env.sh
timeout 1500 bash /work/run.sh
after=$(gpu_used); echo "ORACLE: gpu MiB before=$before after=$after"
resp=$(curl -s --max-time 300 localhost:8009/v1/systemone -H 'content-type: application/json' -d '{
  "state": "Shoes arrived two weeks late and in the wrong size. Also I see two charges on my card.",
  "model": "kev-latest",
  "questions": {
    "department":  {"type": "choice", "instructions": "Which team should handle this?",
                    "criteria": {"returns": "Exchanges, refunds, wrong or damaged items",
                                 "shipping": "Delivery status, delays, lost packages",
                                 "billing": "Charges, invoices, payment problems"}},
    "escalate":    {"type": "noul",  "instructions": "Does this need urgent human attention?"},
    "frustration": {"type": "score", "instructions": "How frustrated is the customer?",
                    "criteria": ["Calm", "Frustrated", "Very angry"]}
  }}')
echo "ORACLE: response=$resp"
python3 - "$resp" <<'PY'
import json, sys
r = json.loads(sys.argv[1])
assert r["answers"]["department"]["choice"] in {"returns", "shipping", "billing"}, r
PY
test $((after - before)) -gt 500 || { echo "ORACLE: GPU memory did not rise; not running on GPU"; exit 1; }
echo "ORACLE PASS"
