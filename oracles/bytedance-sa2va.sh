set -e
source /work/env.sh
cd /work/Sa2VA
export PYTHONPATH=.
O=$(mktemp -d /tmp/sa2va_oracle.XXXXXX)
mkdir -p $O/frames $O/out
python - "$O/frames" <<'PY'
import cv2, sys
cap = cv2.VideoCapture('assets/videos/gf_exp1.mp4')
n = int(cap.get(cv2.CAP_PROP_FRAME_COUNT)); assert n > 8, n
k = 0
for i in range(0, n, max(1, n // 4)):
    cap.set(cv2.CAP_PROP_POS_FRAMES, i)
    ok, f = cap.read()
    if not ok: continue
    f = cv2.resize(f, (448, int(448 * f.shape[0] / f.shape[1])))
    cv2.imwrite('%s/%03d.jpg' % (sys.argv[1], k), f); k += 1
    if k == 4: break
assert k >= 3
PY
timeout 5400 python projects/sa2va/demo/demo.py $O/frames --model_path ByteDance/Sa2VA-1B --work-dir $O/out --text "<image>Please segment the man." 2>&1 | tee $O/log.txt
grep -q "The output is:" $O/log.txt
grep -q "\[SEG\]" $O/log.txt
N=$(ls $O/out/*.jpg | wc -l)
[ "$N" -ge 3 ]
for f in $O/out/*.jpg; do [ "$(stat -c %s $f)" -gt 5000 ]; done
echo "ORACLE PASS"
