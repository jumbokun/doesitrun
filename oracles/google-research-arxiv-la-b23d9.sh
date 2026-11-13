set -e
source /work/env.sh
cd /work/arxiv-latex-cleaner
T=$(mktemp -d /tmp/oracle.XXXXXX)
mkdir -p $T/paper
cp -r test_data/tex/. $T/paper/
timeout 600 python -m arxiv_latex_cleaner $T/paper --resize_images --im_size 100 --images_allowlist='{"images/im2_included.jpg":50}'
O=$T/paper_arXiv
test -f $O/main.tex
test -f $O/images/im1_included.png
test -f $O/images/im2_included.jpg
test ! -e $O/main.aux
test ! -e $O/images/im_not_included.png
test ! -e $O/figures/figure_not_included.tex
test ! -e $O/main.bib
if grep -q "Whole line comment" $O/main.tex; then echo "comments remain"; exit 1; fi
grep -q "This is a percent" $O/main.tex
python - $O <<'P'
import sys
from PIL import Image
o=sys.argv[1]
for f in ["images/im1_included.png","images/im2_included.jpg"]:
    im=Image.open(o+"/"+f); print(f, im.size)
    assert max(im.size)<=100
P
echo ORACLE PASS
