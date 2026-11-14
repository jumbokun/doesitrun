set -e
source /work/env.sh
cd /work/PaddleDetection
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
# v1 grepped the log for "bbox", but ppdet/engine/trainer.py:1277 logs
# "Detection bbox results save in ..." for every saved image, even with zero detections.
# v2 also asks for the documented --save_results flag (docs/tutorials/GETTING_STARTED.md:58), which makes
# COCOMetric write <output_dir>/bbox.json (ppdet/metrics/metrics.py:133-140, trainer.py:1178 sets output_eval=output_dir),
# and checks the detections themselves. Exit status is not asserted (as in v1); the outputs are.
timeout 1800 python tools/infer.py -c configs/picodet/picodet_s_320_coco_lcnet.yml \
  -o use_gpu=False weights=https://paddledet.bj.bcebos.com/models/picodet_s_320_coco_lcnet.pdparams \
  --infer_img=demo/000000014439.jpg --output_dir="$OUT" --save_results=True 2>&1 | tee "$OUT/log.txt"
IMG="$OUT/000000014439.jpg"   # trainer.py:1284-1290 keeps the input file name
test -f "$IMG"
[ "$(stat -c %s "$IMG")" -gt 10000 ]
cmp -s "$IMG" demo/000000014439.jpg && { echo "output identical to input"; exit 1; }
test -s "$OUT/bbox.json" || { echo "no bbox.json"; exit 1; }
python - "$OUT/bbox.json" "$IMG" <<'P'
import json, sys
from PIL import Image
d = json.load(open(sys.argv[1]))
# entries: image_id, category_id, bbox [x,y,w,h], score (ppdet/metrics/json_results.py get_det_res)
good = [x for x in d if x["score"] >= 0.5]
assert len(good) >= 3, "too few confident detections: %d" % len(good)
# demo/000000014439.jpg shows several people flying a kite on a field; COCO category 1 = person
# (default COCO categories are used when no anno file exists, ppdet/data/source/category.py:75-82).
persons = [x for x in good if x["category_id"] == 1]
assert len(persons) >= 2, "expected people among detections, got %s" % sorted({x["category_id"] for x in good})
W, H = Image.open(sys.argv[2]).size
for x in good:
    bx, by, bw, bh = x["bbox"]
    assert bw > 1 and bh > 1 and bx > -5 and by > -5 and bx + bw < W + 5 and by + bh < H + 5, x
print("detections >=0.5:", len(good), "persons:", len(persons))
P
echo ORACLE PASS
