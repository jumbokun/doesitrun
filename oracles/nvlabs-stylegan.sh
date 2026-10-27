set -e
source /work/env.sh
cd /work/stylegan
rm -f results/example.png
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
timeout 5400 python pretrained_example.py 2>&1 | tee $OUT/log.txt
test -f results/example.png
cp results/example.png $OUT/example.png
python - "$OUT/example.png" <<'P'
import sys, numpy as np, PIL.Image
im = PIL.Image.open(sys.argv[1]); a = np.asarray(im.convert('RGB'))
assert im.size == (1024,1024), im.size
assert a.std() > 20, a.std()
print('image ok', im.size, a.mean(), a.std())
P
grep -q "26219627" $OUT/log.txt
echo "ORACLE PASS"
