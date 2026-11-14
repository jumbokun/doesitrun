set -e
source /work/env.sh
cd /work/models/paddlecv

# --- Part 1: docs/GETTING_STARTED.md "部署示例" image classification
# (PP-LCNet, the smaller listed sibling of PP-HGNet; README.md model table) ---
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
timeout 1800 python -u tools/predict.py --config=configs/single_op/PP-LCNet.yml --input=demo/ILSVRC2012_val_00020010.jpeg --output_dir="$OUT"
test -s "$OUT/clas_output.json"          # ppcv/ops/output/classification.py:52
test -s "$OUT/ILSVRC2012_val_00020010.jpeg"
python - "$OUT/clas_output.json" <<'P'
import json,sys
d=json.load(open(sys.argv[1]))
assert len(d)==1, d
r=d[0]
g=lambda k:[v for kk,v in r.items() if kk.split('.')[-1]==k][0]
ids=g('class_ids'); sc=g('scores'); names=g('label_names')
assert len(ids)==5 and len(sc)==5 and len(names)==5, r   # PP-LCNet.yml Topk topk: 5
assert all(0<=s<=1 for s in sc) and sc==sorted(sc,reverse=True) and sc[0]>0.05, sc
assert all(isinstance(n,str) and n for n in names), names
# demo/ILSVRC2012_val_00020010.jpeg shows a Weimaraner (ImageNet-1k class 178)
assert 178 in ids and any('Weimaraner' in n for n in names), r
print(r)
P

# --- Part 2: docs/INSTALL.md:74-88 "快速体验" object detection (PP-YOLOE+); its reference
# output demo/000000014439_output.jpg shows a dozen "person" boxes ---
OUT2=$(mktemp -d /tmp/oracle_det.XXXXXX)
timeout 1800 python -u tools/predict.py --config=configs/single_op/PP-YOLOE+.yml --input=demo/000000014439.jpg --output_dir="$OUT2"
test -s "$OUT2/det_output.json"          # ppcv/ops/output/detection.py:114
test -s "$OUT2/000000014439.jpg"
python - "$OUT2/det_output.json" <<'P'
import json,sys
d=json.load(open(sys.argv[1]))
assert len(d)==1, d
r=d[0]
g=lambda k:[v for kk,v in r.items() if kk.split('.')[-1]==k][0]
boxes=g('dt_bboxes'); sc=g('dt_scores'); names=g('dt_cls_names')
assert len(boxes)==len(sc)==len(names)>0, r
assert all(s>=0.5-1e-6 for s in sc), sc   # PP-YOLOE+.yml ParserDetResults threshold: 0.5
assert all(len(b)==4 and b[0]<b[2] and b[1]<b[3] for b in boxes), boxes
npers=sum(1 for n in names if n=='person')
print("detections", len(names), "persons", npers, sorted(set(names)))
assert npers>=5, names
P
echo "ORACLE PASS"
