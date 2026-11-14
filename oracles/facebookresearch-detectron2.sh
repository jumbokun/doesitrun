set -e
source /work/env.sh
cd /work/detectron2
O=$(mktemp -d /tmp/oracle.XXXXXX)
# No natural photo is bundled in the repo; use the standard COCO val image (two cats, two remotes, a couch).
timeout 300 curl -fsSL --retry 3 -o $O/in.jpg http://images.cocodataset.org/val2017/000000039769.jpg
mkdir $O/out
cd demo
# GETTING_STARTED.md:16-32 (demo.py; "MODEL.DEVICE cpu" after --opts; --output <dir> for images)
set -o pipefail
timeout 3000 python demo.py --config-file ../configs/COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x.yaml \
  --input $O/in.jpg --output $O/out \
  --opts MODEL.WEIGHTS detectron2://COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x/137849600/model_final_f10217.pkl MODEL.DEVICE cpu 2>&1 | tee $O/log.txt
set +o pipefail
test -s $O/out/in.jpg
# demo.py logs "<path>: detected N instances in X.XXs" for every input (demo/demo.py:113-123),
# with the default --confidence-threshold 0.5 (demo/demo.py:62-65).
n=$(grep -oE 'detected [0-9]+ instances' $O/log.txt | tail -1 | grep -oE '[0-9]+' || true)
echo "instances: $n"
[ -n "$n" ] || { echo "no 'detected N instances' line in demo log"; exit 1; }
[ "$n" -ge 2 ] || { echo "too few instances: $n"; exit 1; }
python - $O <<'PY'
import sys, os
import numpy as np
from PIL import Image
o = sys.argv[1]
a = Image.open(o + "/in.jpg"); b = Image.open(o + "/out/in.jpg")
assert a.size == b.size, (a.size, b.size)
assert os.path.getsize(o + "/out/in.jpg") > 10000
d = np.abs(np.asarray(a.convert("RGB"), int) - np.asarray(b.convert("RGB"), int)).mean()
print("mean abs diff", d)
assert d > 3, d
PY
echo ORACLE PASS
