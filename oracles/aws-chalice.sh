set -e
source /work/env.sh
cd /work/chalice
timeout 1500 bash /work/run.sh
out=$(mktemp -d /tmp/oracle.XXXXXX)

# 1. the run.sh server (README Quickstart project) answers GET / with {"hello": "world"}
#    (chalice/templates/0009-legacy/app.py, the default `new-project` template, cli/__init__.py:412)
code=$(curl -s -o $out/resp.json -w '%{http_code}' --max-time 30 http://127.0.0.1:8000/)
[ "$code" = 200 ]
python3 -I -c "import json,sys; assert json.load(open(sys.argv[1]))=={'hello':'world'}" $out/resp.json

# 2. an oracle-controlled project: scaffold with `chalice new-project`, add the two example
#    routes that the generated app.py itself documents in comments (path parameter, POST json_body),
#    and serve it with `chalice local` on another port. v1 scaffolded this project but never ran it.
(cd $out && timeout 120 chalice new-project demoapp)
test -s $out/demoapp/app.py
test -f $out/demoapp/.chalice/config.json
test -f $out/demoapp/requirements.txt
grep -q "@app.route" $out/demoapp/app.py
cat >> $out/demoapp/app.py <<'PY'


@app.route('/hello/{name}')
def hello_name(name):
    return {'hello': name}


@app.route('/users', methods=['POST'])
def create_user():
    return {'user': app.current_request.json_body}
PY
cd $out/demoapp
nohup timeout 900 chalice local --host 127.0.0.1 --port 8765 --no-autoreload > $out/local.log 2>&1 &
LPID=$!
trap 'kill $LPID 2>/dev/null || true' EXIT
for i in $(seq 60); do curl -sf -o /dev/null http://127.0.0.1:8765/ && break; sleep 1; done
curl -sf --max-time 30 http://127.0.0.1:8765/ -o $out/r0.json || { cat $out/local.log; exit 1; }
curl -sf --max-time 30 http://127.0.0.1:8765/hello/oracle -o $out/r1.json
curl -sf --max-time 30 -X POST -H 'Content-Type: application/json' -d '{"name":"ada","n":3}' \
  http://127.0.0.1:8765/users -o $out/r2.json
# an undefined route must not be served as 200 (local API Gateway emulation returns 403/404)
nf=$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 http://127.0.0.1:8765/no-such-route)
[ "$nf" != 200 ]
python3 -I - $out <<'P'
import json, sys, os
d = sys.argv[1]
j = lambda n: json.load(open(os.path.join(d, n)))
assert j("r0.json") == {"hello": "world"}, j("r0.json")
assert j("r1.json") == {"hello": "oracle"}, j("r1.json")
assert j("r2.json") == {"user": {"name": "ada", "n": 3}}, j("r2.json")
print("chalice local ok")
P
echo "ORACLE PASS"
