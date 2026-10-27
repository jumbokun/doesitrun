set -e
source /work/env.sh
cd /work/cascadia-code
rm -rf build
timeout 3000 python build.py -P -NF -M -I
F=$(ls build/ttf/CascadiaCode*.ttf | head -1)
echo "font: $F"
python - "$F" <<'P'
import sys, os
from fontTools.ttLib import TTFont
p = sys.argv[1]
assert os.path.getsize(p) > 100000, "font too small"
f = TTFont(p)
names = " ".join(n.toUnicode() for n in f["name"].names)
assert "Cascadia Code" in names, "name missing"
assert "fvar" in f, "not variable"
assert "GSUB" in f, "no ligature features"
cmap = f.getBestCmap()
assert ord("A") in cmap and 0x2192 in cmap, "missing glyphs"
print("glyphs", len(f.getGlyphOrder()))
P
echo ORACLE PASS
