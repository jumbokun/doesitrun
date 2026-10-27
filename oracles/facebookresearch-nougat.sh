set -e
source /work/env.sh
cd /work/nougat
D=$(mktemp -d /tmp/nougat_oracle.XXXXXX)
python - "$D/in.pdf" <<'PY'
import sys
from PIL import Image, ImageDraw, ImageFont
img = Image.new("RGB", (1240, 1754), "white")
d = ImageDraw.Draw(img)
fp = None
for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf","/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf"]:
    try:
        ImageFont.truetype(p, 20); fp = p; break
    except Exception: pass
def f(s): return ImageFont.truetype(fp, s) if fp else ImageFont.load_default(size=s)
d.text((330, 150), "Neural Optical Understanding", font=f(44), fill="black")
d.text((120, 260), "Abstract", font=f(32), fill="black")
y = 330
for line in ["We present a method for converting scientific documents into",
             "markup language. The model reads page images and produces",
             "text, and it works well on academic papers and reports.",
             "1 Introduction",
             "Scientific knowledge is stored in documents such as papers."]:
    d.text((120, y), line, font=f(28), fill="black"); y += 55
img.save(sys.argv[1], "PDF", resolution=150)
PY
timeout 3000 nougat "$D/in.pdf" -o "$D/out" --no-skipping -p 1
F="$D/out/in.mmd"
test -s "$F"
echo "--- output:"; cat "$F"
SZ=$(wc -c < "$F"); test "$SZ" -gt 40
grep -qiE "abstract|introduction|document|scientific|model|markup" "$F"
echo "ORACLE PASS"
