set -e
set -o pipefail
source /work/env.sh
cd /work/PaddleX
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
python - "$OUT/in.png" <<'PY'
import sys
from PIL import Image, ImageDraw, ImageFont
img = Image.new("RGB", (900, 300), "white")
d = ImageDraw.Draw(img)
try:
    f = ImageFont.truetype("DejaVuSans.ttf", 64)
except Exception:
    f = ImageFont.load_default(size=64)
d.text((30, 30), "Hello PaddleX OCR", fill="black", font=f)
d.text((30, 150), "Reproducible 2024", fill="black", font=f)
img.save(sys.argv[1])
PY
# README_en.md:635-641 OCR pipeline command, --device cpu
timeout 3000 paddlex --pipeline OCR --input "$OUT/in.png" \
  --use_doc_orientation_classify False --use_doc_unwarping False \
  --use_textline_orientation False --save_path "$OUT/res" --device cpu 2>&1 | tee "$OUT/log.txt"
ls -la "$OUT/res"
# visualization: paddlex/inference/pipelines/ocr/result.py:113 ("ocr_res_img")
find "$OUT/res" -type f -size +5k \( -name "*.png" -o -name "*.jpg" \) | grep -q . || { echo "no result image"; exit 1; }
grep -q "rec_texts" "$OUT/log.txt" || { echo "no rec_texts printed"; exit 1; }
# v2: read the recognized text from the saved JSON (save_to_json writes <stem>_res.json with a top-level
# "rec_texts" list: paddlex/inference/common/result/mixin.py:216-245, ocr/result.py:185). v1 grepped the whole log
# for "paddle", which always matches PaddleX's own model-download/log lines, so it could not detect bad OCR.
python - "$OUT/res" <<'PY'
import sys, json, glob
files = glob.glob(sys.argv[1] + "/*.json")
assert files, "no json"
texts = []
for p in files:
    d = json.load(open(p))
    if isinstance(d, dict) and "res" in d and isinstance(d["res"], dict): d = d["res"]
    if isinstance(d, dict) and "rec_texts" in d: texts += d["rec_texts"]
assert texts, "no rec_texts in saved json"
t = "".join(texts).upper().replace(" ", "")
print("TEXT:", t)
assert "PADDLEX" in t, "first line not recognized"
assert "REPRODUC" in t or "2024" in t, "second line not recognized"
PY
echo "ORACLE PASS"
