set -e
source /work/env.sh
cd /work/Sa2VA
export PYTHONPATH=.
O=$(mktemp -d /tmp/sa2va_oracle.XXXXXX)
mkdir -p $O/frames $O/out
python - "$O/frames" <<'PY'
import cv2, sys
cap = cv2.VideoCapture('assets/videos/gf_exp1.mp4')   # bundled clip: 600 frames, 960x540
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
# README Quick Start option 1 (projects/sa2va/README.md:84-88), with the smaller public Sa2VA-1B
timeout 5400 python projects/sa2va/demo/demo.py $O/frames --model_path ByteDance/Sa2VA-1B --work-dir $O/out --text "<image>Please segment the man." 2>&1 | tee $O/log.txt
grep -q "The output is:" $O/log.txt          # demo.py prints this before the prediction
grep -q "\[SEG\]" $O/log.txt
N=$(ls $O/out/*.jpg | wc -l)
[ "$N" -ge 3 ]
# v2: the overlays must actually contain a mask. demo.py visualize() draws the predicted binary mask in green at
# alpha 0.4 over the original frame (mmengine Visualizer.draw_binary_masks), so masked pixels differ clearly from
# the input frame; an empty or all-image mask means segmentation did not work. The man is visible in every frame.
python - "$O/frames" "$O/out" <<'PY'
import sys, os, cv2, numpy as np
fr, out = sys.argv[1], sys.argv[2]
fracs = []
for name in sorted(os.listdir(out)):
    if not name.endswith(".jpg"): continue
    a = cv2.imread(os.path.join(fr, name)); b = cv2.imread(os.path.join(out, name))
    assert a is not None and b is not None and a.shape == b.shape, name
    diff = np.abs(b.astype(int) - a.astype(int)).sum(axis=2)
    frac = float((diff > 60).mean())
    fracs.append(frac); print(name, "changed fraction %.3f" % frac)
assert fracs and max(fracs) > 0.01, "no visible mask in any overlay"
assert sum(1 for f in fracs if 0.002 < f < 0.9) >= 2, "masks empty or covering the whole frame"
PY
echo "ORACLE PASS"
