set -e
source /work/env.sh
cd /work/AI-Infra-Guard
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/fake.py <<'PY'
import sys
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
sleep 2
if command -v aig-infra-scan >/dev/null 2>&1; then
  CMD="aig-infra-scan"
elif command -v ai-infra-guard >/dev/null 2>&1; then
  CMD="ai-infra-guard scan"
else
  CMD="go run ./cmd/cli scan"
fi
timeout 600 $CMD -t http://127.0.0.1:18434 --lang en --json -o $OUT/result.json > $OUT/stdout.txt 2>&1 || { cat $OUT/stdout.txt; exit 1; }
cat $OUT/stdout.txt | tail -20
if [ -s $OUT/result.json ]; then R=$OUT/result.json; else R=$OUT/stdout.txt; fi
echo "result file: $R ($(wc -c < $R) bytes)"
grep -qi ollama $R || { echo "ollama not detected"; exit 1; }
grep -q "18434" $R || { echo "target missing"; exit 1; }
echo ORACLE PASS
