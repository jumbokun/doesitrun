set -e
source /work/env.sh
cd /work/Qwen-MM-Plugins
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > "$OUT/client.py" <<'PYEOF'
import json, os, subprocess, sys, time
repo, out = sys.argv[1], sys.argv[2]; os.makedirs(out, exist_ok=True)
srv = os.path.join(repo, "src/capabilities/core/qwen_mm_plugins_core")
env = dict(os.environ, QWEN_MM_NATIVE_MODE="1")
p = subprocess.Popen([sys.executable, srv], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env)
def send(m): p.stdin.write(json.dumps(m) + "\n"); p.stdin.flush()
def recv(i):
    while True:
        l = p.stdout.readline()
        if not l: raise SystemExit("server closed: " + p.stderr.read()[-800:])
        try: m = json.loads(l)
        except Exception: continue
        if m.get("id") == i: return m
send({"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"oracle","version":"0"}}})
recv(1)
send({"jsonrpc":"2.0","method":"notifications/initialized"})
n = [1]
def call(name, args):
    n[0] += 1
    send({"jsonrpc":"2.0","id":n[0],"method":"tools/call","params":{"name":name,"arguments":args}})
    r = recv(n[0])
    assert "error" not in r, r
    res = r["result"]
    assert not res.get("isError"), res
    return res["content"]
send({"jsonrpc":"2.0","id":99,"method":"tools/list","params":{}})
names = {t["name"] for t in recv(99)["result"]["tools"]}
for t in ("read_image","save_view","crop","visualize","media_info"):
    assert t in names, (t, names)
pdf = os.path.join(repo, "tests/assets/sample.pdf")
c = call("save_view", {"file_path": pdf, "pages": "1", "output_dir": out})
pngs = sorted(f for f in os.listdir(out) if f.endswith(".png"))
assert pngs, os.listdir(out)
page = os.path.join(out, pngs[0])
assert os.path.getsize(page) > 2000
assert any(x["type"] == "image" for x in c), "no image preview returned"
cropped = os.path.join(out, "crop.png")
call("crop", {"image_path": page, "box": [0, 0, 500, 500], "output_path": cropped})
from PIL import Image
a, b = Image.open(page), Image.open(cropped)
assert abs(b.width - a.width/2) <= 2 and abs(b.height - a.height/2) <= 2, (a.size, b.size)
c = call("visualize", {"file_path": os.path.join(repo, "tests/assets/sample.csv")})
txt = " ".join(x.get("text", "") for x in c if x["type"] == "text")
first = "Tokyo"
assert first and first in txt, (first, txt[:300])
c = call("read_image", {"image_path": cropped})
assert any(x["type"] == "image" for x in c), "read_image returned no image"
p.stdin.close(); p.terminate()
print("client ok")
PYEOF
timeout 600 python3 "$OUT/client.py" /work/Qwen-MM-Plugins "$OUT/out"
ls -l "$OUT/out"
echo "ORACLE PASS"
