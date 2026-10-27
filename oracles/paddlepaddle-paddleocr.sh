set -e
source /work/env.sh
cd /work/PaddleOCR
OUT=$(mktemp -d /tmp/oracle_XXXXXX)
python - "$OUT/in.png" <<'PY'
import sys
from PIL import Image, ImageDraw, ImageFont
import glob
fs = glob.glob('/usr/share/fonts/**/*.ttf', recursive=True)
try:
    f = ImageFont.truetype(fs[0], 56) if fs else ImageFont.load_default(size=56)
except Exception:
    f = ImageFont.load_default(size=56)
im = Image.new('RGB', (900, 300), 'white')
d = ImageDraw.Draw(im)
d.text((40, 40), "HELLO PADDLEOCR", fill='black', font=f)
d.text((40, 160), "Reproducibility Test 2024", fill='black', font=f)
im.save(sys.argv[1])
PY
timeout 1500 paddleocr ocr -i "$OUT/in.png" --save_path "$OUT/res" \
  --use_doc_orientation_classify False --use_doc_unwarping False --use_textline_orientation False \
  > "$OUT/stdout.txt" 2>&1 || { cat "$OUT/stdout.txt"; exit 1; }
cat "$OUT/stdout.txt" | tail -30
ls -la "$OUT/res"
J=$(ls "$OUT"/res/*.json | head -1)
test -s "$J"
python - "$J" <<'PY'
import sys, json
d = json.load(open(sys.argv[1]))
t = "".join(d["rec_texts"]).upper().replace(" ", "")
print("TEXT:", t)
assert "HELLO" in t and "PADDLE" in t, "expected text not recognized"
PY
ls "$OUT"/res/*.png >/dev/null
echo "ORACLE PASS"
