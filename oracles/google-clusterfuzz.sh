set -e
source /work/env.sh
cd /work/clusterfuzz
timeout 1500 bash /work/run.sh
out=$(mktemp -d /tmp/oracle.XXXX)
# Home page: '/' -> testcase_list.Handler when not OSS-Fuzz (src/appengine/server.py:124).
code=$(timeout 120 curl -sL -o $out/index.html -w '%{http_code}' http://localhost:9000/)
echo "http / $code"
[ "$code" = 200 ]
[ $(wc -c < $out/index.html) -gt 500 ]
grep -qi clusterfuzz $out/index.html
# NOTE: /login is deliberately NOT checked. login.Handler.get is decorated with
# @handler.unsupported_on_local_server (src/appengine/handlers/login.py:35), which returns
# HTTP 400 on the local dev server by design (src/appengine/libs/handler.py:147-160).
#
# Datastore check: `run_server --bootstrap` starts a thread that runs
# `butler.py run setup --non-dry-run --local` after ~10 s (src/local/butler/run_server.py:28-42),
# which creates the afl / libFuzzer / honggfuzz fuzzer entities (src/local/butler/scripts/setup.py:332-358).
# /fuzzers renders them from the datastore emulator, base64-JSON-encoded in the page
# (src/appengine/handlers/fuzzers.py:50-78, src/appengine/templates/fuzzers.html:51,
#  src/appengine/handlers/base_handler.py:93-96). The local dev user is admin (src/appengine/libs/auth.py:64,160-162).
cat > $out/check.py <<'PY'
import base64, json, re, sys
html = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"fuzzers:\s*JSON\.parse\(atob\('([A-Za-z0-9+/=]*)'\)\)", html)
assert m, "no fuzzers payload in /fuzzers page"
data = json.loads(base64.b64decode(m.group(1)).decode("utf-8"))
names = {f.get("name") for f in data if isinstance(f, dict)}
print("fuzzers:", sorted(n for n in names if n))
assert {"afl", "libFuzzer", "honggfuzz"} <= names, names
PY
ok=0
code2=none
for i in $(seq 1 60); do
  code2=$(timeout 60 curl -sL -o $out/fuzzers.html -w '%{http_code}' http://localhost:9000/fuzzers || true)
  if [ "$code2" = 200 ] && python3 $out/check.py $out/fuzzers.html; then ok=1; break; fi
  sleep 5
done
[ "$ok" = 1 ] || { echo "bootstrapped fuzzers never appeared on /fuzzers (last http $code2)"; exit 1; }
echo "ORACLE PASS"
