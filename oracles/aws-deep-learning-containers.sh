set -e
source /work/env.sh
cd /work/deep-learning-containers
timeout 1500 bash /work/run.sh
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
for i in $(seq 1 60); do
  curl -sf http://localhost:8080/health >/dev/null && break
  sleep 5
done
code=$(curl -s -o $OUT/health.json -w '%{http_code}' http://localhost:8080/health)
[ "$code" = "200" ] || { echo "health $code"; exit 1; }
code=$(timeout 600 curl -s -o $OUT/chat.json -w '%{http_code}' http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"What is the capital of France? Answer in one sentence."}],"max_tokens":64,"temperature":0}')
[ "$code" = "200" ] || { echo "chat $code"; cat $OUT/chat.json; exit 1; }
python3 - $OUT/chat.json <<'P'
import json,sys
d=json.load(open(sys.argv[1]))
m=d["choices"][0]["message"]["content"]
print("reply:",m)
assert len(m.strip())>3, "empty reply"
assert "paris" in m.lower(), "reply does not mention Paris"
assert d.get("usage",{}).get("completion_tokens",0)>0
P
echo "ORACLE PASS"
