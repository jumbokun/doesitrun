set -e
source /work/env.sh
cd /work/HunyuanOCR
timeout 1500 bash /work/run.sh
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
# v2: use the repo's bundled smoke-test page (llama_cpp/test_assets/ocr/0.png, the image whose expected output is
# shown in docs/llama_cpp.md section 6.3) and only the Python stdlib. v1 needed PIL, which the docs' conversion env
# (section 2: huggingface_hub transformers torch openai) does not install.
test -s llama_cpp/test_assets/ocr/0.png
timeout 2400 python3 - "$OUT" llama_cpp/test_assets/ocr/0.png <<'PY'
import sys, base64, json, urllib.request
out, img = sys.argv[1], sys.argv[2]
b = base64.b64encode(open(img, "rb").read()).decode()
# Official doc_parse prompt: inference/utils/tasks.py TASK_PROMPTS["doc_parse"] (chat.py's default task).
prompt = ("提取文档图片中正文的所有信息用markdown格式表示，其中页眉、页脚部分忽略，表格用html格式表达，"
          "文档中公式用latex格式表示，按照阅读顺序组织进行解析。")
# model alias HYVL and endpoint: docs/llama_cpp.md section 4.1
body = {"model": "HYVL", "max_tokens": 3000, "temperature": 0, "messages": [{"role": "user", "content": [
    {"type": "image_url", "image_url": {"url": "data:image/png;base64," + b}},
    {"type": "text", "text": prompt}]}]}
req = urllib.request.Request("http://127.0.0.1:8080/v1/chat/completions", json.dumps(body).encode(),
                             {"Content-Type": "application/json"})
r = urllib.request.urlopen(req, timeout=2300)
assert r.status == 200, r.status
t = json.load(r)["choices"][0]["message"]["content"]
open(out + "/resp.txt", "w").write(t)
print("RESPONSE (first 800 chars):", t[:800])
low = t.lower()
# Words printed on the page (and in the docs/llama_cpp.md 6.3 sample output: "Jacobson semisimple",
# "Corollary 8.35(ii)"); "Maschke" is in the Theorem 8.47 heading further down the page.
need = ["jacobson", "semisimple", "corollary", "composition series", "maschke"]
hit = [w for w in need if w in low]
print("matched", hit)
assert len(hit) >= 4, "expected page text missing: %s" % [w for w in need if w not in low]
PY
echo "ORACLE PASS"
