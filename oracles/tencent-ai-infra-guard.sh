set -e
source /work/env.sh
cd /work/AI-Infra-Guard
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
# Fake Ollama service matching data/fingerprints/ollama.yaml:
#   GET /            body="Ollama is running"
#   GET /api/version extractor regex '{"version":"(\d+\.\d+\.?\d+?)"}'
cat > $OUT/fake.py <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/api/version':
            b = b'{"version":"0.1.20"}'; t = 'application/json'
        elif self.path == '/':
            b = b'Ollama is running'; t = 'text/plain'
        else:
            self.send_response(404); self.end_headers(); return
        self.send_response(200); self.send_header('Content-Type', t)
        self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self, *a): pass
HTTPServer(('127.0.0.1', 18434), H).serve_forever()
PY
python3 $OUT/fake.py &
SP=$!
trap 'kill $SP 2>/dev/null' EXIT
for i in $(seq 1 20); do curl -s http://127.0.0.1:18434/ >/dev/null 2>&1 && break; sleep 0.5; done
if command -v aig-infra-scan >/dev/null 2>&1; then
  CMD="aig-infra-scan"                 # infra-scan/README.md Quick start
elif command -v ai-infra-guard >/dev/null 2>&1; then
  CMD="ai-infra-guard scan"
else
  CMD="go run ./cmd/cli scan"
fi
timeout 600 $CMD -t http://127.0.0.1:18434 --lang en --json -o $OUT/result.json > $OUT/stdout.txt 2>&1 || { cat $OUT/stdout.txt; exit 1; }
tail -20 $OUT/stdout.txt
# --json -o writes ResultsJSON(results): a JSON array of HttpResult (common/runner/runner.go:563-568,
# common/runner/result.go:38-47). HttpResult also serialises the raw response body as "Resp", so a plain
# grep for "ollama" would match "Ollama is running" even with no fingerprint rules loaded; check the
# structured "fingerprints" field instead.
python3 - $OUT/result.json <<'PY'
import json, sys
rows = json.load(open(sys.argv[1]))
assert isinstance(rows, list) and rows, rows
hit = [r for r in rows if '18434' in (r.get('url') or '')]
assert hit, ("target missing", [r.get('url') for r in rows])
r = hit[0]
fps = r.get('fingerprints') or []
names = [f.get('name') for f in fps]
print("fingerprints:", fps)
assert 'ollama' in names, ("ollama not fingerprinted", names)
ver = [f.get('version') for f in fps if f.get('name') == 'ollama'][0]
assert ver == '0.1.20', ("version not extracted from /api/version", ver)
adv = r.get('advisories') or []
# data/vuln_en/ollama/*.yaml has rules such as version <= "0.3.14" that cover 0.1.20
assert adv, "no advisories matched for ollama 0.1.20"
print("advisories:", len(adv), [a.get('info', {}).get('cve') for a in adv][:5])
PY
echo ORACLE PASS
