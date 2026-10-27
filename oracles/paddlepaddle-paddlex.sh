set -e
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
timeout 3000 paddlex --pipeline OCR --input "$OUT/in.png" \
  --use_doc_orientation_classify False --use_doc_unwarping False \
  --use_textline_orientation False --save_path "$OUT/res" --device cpu 2>&1 | tee "$OUT/log.txt"
ls -la "$OUT/res"
find "$OUT/res" -type f -size +5k \( -name "*.png" -o -name "*.jpg" \) | grep -q . || { echo "no result image"; exit 1; }
find "$OUT/res" -name "*.json" | grep -q . || { echo "no json"; exit 1; }
tr 'A-Z' 'a-z' < "$OUT/log.txt" | grep -q "paddle" || { echo "expected text not recognized"; exit 1; }
grep -q "rec_texts" "$OUT/log.txt" || { echo "no rec_texts"; exit 1; }
echo "ORACLE PASS"
