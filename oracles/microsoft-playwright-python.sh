set -e
source /work/env.sh
cd /work/playwright-python
O=$(mktemp -d /tmp/oracle.XXXXXX)
mkdir $O/www
cat > $O/www/index.html <<'H'
<html><head><title>Oracle Page</title></head><body style="background:#ddf"><h1 id="h">Hello Oracle 4242</h1><p>some filler text to render</p></body></html>
H
(cd $O/www && python -m http.server 8765 >/dev/null 2>&1 & echo $! > $O/pid)
trap 'kill $(cat $O/pid) 2>/dev/null || true' EXIT
sleep 2
cat > $O/t.py <<'P'
import sys
from playwright.sync_api import sync_playwright
out = sys.argv[1]
with sync_playwright() as p:
    b = p.chromium.launch()
    page = b.new_page()
    page.goto('http://127.0.0.1:8765/index.html')
    assert page.title() == 'Oracle Page', page.title()
    assert page.inner_text('#h') == 'Hello Oracle 4242'
    assert page.evaluate('1+2') == 3
    page.screenshot(path=out + '/example-chromium.png')
    b.close()
print('script ok')
P
timeout 600 python $O/t.py $O
python - "$O/example-chromium.png" <<'P'
import sys, os
f = sys.argv[1]
d = open(f, 'rb').read()
assert d[:8] == b'\x89PNG\r\n\x1a\n', 'not png'
assert len(d) > 1000, len(d)
print('png size', len(d))
P
echo "ORACLE PASS"
