set -e
source /work/env.sh
cd /work/detectron2
O=$(mktemp -d /tmp/oracle.XXXXXX)
curl -fsSL -o $O/in.jpg http://images.cocodataset.org/val2017/000000039769.jpg
mkdir $O/out
cd demo
timeout 3000 python demo.py --config-file ../configs/COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x.yaml \
  --input $O/in.jpg --output $O/out \
  --opts MODEL.WEIGHTS detectron2://COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x/137849600/model_final_f10217.pkl MODEL.DEVICE cpu 2>&1 | tee $O/log.txt
test -s $O/out/in.jpg
python - $O <<'PY'
import sys,os
from PIL import Image
o=sys.argv[1]
a=Image.open(o+"/in.jpg"); b=Image.open(o+"/out/in.jpg")
assert a.size==b.size, (a.size,b.size)
assert os.path.getsize(o+"/out/in.jpg")>10000
import numpy as np
d=np.abs(np.asarray(a.convert("RGB"),int)-np.asarray(b.convert("RGB"),int)).mean()
assert d>3, d
PY
echo ORACLE PASS
