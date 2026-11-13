set -e
source /work/env.sh
cd /work/gpt-oss
timeout 1500 bash /work/run.sh
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
curl -s -m 1800 -o $OUT/resp.json -w '%{http_code}' http://127.0.0.1:11434/v1/chat/completions \
 -H 'Content-Type: application/json' \
 -d '{"model":"gpt-oss:20b","messages":[{"role":"user","content":"What is 2+2? Answer briefly."}],"max_tokens":300,"stream":false}' > $OUT/code
[ "$(cat $OUT/code)" = "200" ] || { echo "bad http $(cat $OUT/code)"; cat $OUT/resp.json; exit 1; }
python3 -I - $OUT/resp.json <<'P'
import json,sys
r=json.load(open(sys.argv[1]))
m=r["choices"][0]["message"]
txt=(m.get("content") or "")+(m.get("reasoning") or "")+(m.get("reasoning_content") or "")
print(txt)
assert r["model"].startswith("gpt-oss") and len(txt.strip())>0
assert r["usage"]["completion_tokens"]>0
P
echo "ORACLE PASS"
