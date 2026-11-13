set -e
source /work/env.sh
cd /work/HunyuanOCR
timeout 1500 bash /work/run.sh
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
python3 - "$OUT/img.png" <<'PY'
import sys
from PIL import Image, ImageDraw, ImageFont
f=None
for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf","/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"]:
    try: f=ImageFont.truetype(p,64); break
    except Exception: pass
if f is None: f=ImageFont.load_default(size=64)
im=Image.new("RGB",(900,300),"white"); d=ImageDraw.Draw(im)
d.text((40,40),"HUNYUAN OCR",fill="black",font=f)
d.text((40,160),"Invoice 20481",fill="black",font=f)
im.save(sys.argv[1])
PY
python3 - "$OUT" <<'PY'
import sys,base64,json,urllib.request
out=sys.argv[1]
b=base64.b64encode(open(out+"/img.png","rb").read()).decode()
body={"model":"HYVL","max_tokens":256,"temperature":0,"messages":[{"role":"user","content":[
 {"type":"image_url","image_url":{"url":"data:image/png;base64,"+b}},
 {"type":"text","text":"Extract all the text in the image."}]}]}
req=urllib.request.Request("http://127.0.0.1:8080/v1/chat/completions",json.dumps(body).encode(),{"Content-Type":"application/json"})
r=urllib.request.urlopen(req,timeout=1800)
assert r.status==200
t=json.load(r)["choices"][0]["message"]["content"]
open(out+"/resp.txt","w").write(t); print("RESPONSE:",t)
u=t.upper().replace(" ","")
assert "20481" in u and "HUNYUAN" in u or "INVOICE" in u and "20481" in u, "expected text missing"
PY
echo "ORACLE PASS"
