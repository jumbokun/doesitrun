set -e
source /work/env.sh
cd /work/Unlimited-OCR
OUT=$(mktemp -d /tmp/oracle_XXXXXX)
python - "$OUT" <<'PY'
import sys, os
from PIL import Image, ImageDraw, ImageFont
out = sys.argv[1]
img = Image.new("RGB", (1000, 400), "white")
d = ImageDraw.Draw(img)
try:
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 48)
except Exception:
    f = ImageFont.load_default(size=48)
d.text((40, 60), "Invoice Number 48213", fill="black", font=f)
d.text((40, 160), "Total Amount Due Monday", fill="black", font=f)
d.text((40, 260), "Reproducibility Benchmark", fill="black", font=f)
img.save(os.path.join(out, "page_1.png"))
PY
cat > "$OUT/run.py" <<'PY'
import sys, os, torch
from transformers import AutoModel, AutoTokenizer
out = sys.argv[1]
name = "baidu/Unlimited-OCR-2"
tok = AutoTokenizer.from_pretrained(name, trust_remote_code=True)
model = AutoModel.from_pretrained(name, trust_remote_code=True, use_safetensors=True,
                                  torch_dtype=torch.float32).eval()
text = model.infer(tok, image_file=os.path.join(out, "page_1.png"),
                   output_path=os.path.join(out, "res"), save_results=True)
text = text if isinstance(text, str) else str(text)
open(os.path.join(out, "text.txt"), "w").write(text)
print("OUTPUT:", text)
PY
timeout 6000 python "$OUT/run.py" "$OUT"
test -s "$OUT/text.txt"
T=$(tr 'A-Z' 'a-z' < "$OUT/text.txt")
n=0
for w in "invoice" "48213" "total" "amount" "reproducibility" "benchmark"; do
  echo "$T" | grep -q "$w" && n=$((n+1))
done
echo "matched $n/6"
[ "$n" -ge 4 ]
echo "ORACLE PASS"
