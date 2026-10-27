set -e
source /work/env.sh
cd /work/models/paddlecv
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
timeout 1800 python -u tools/predict.py --config=configs/single_op/PP-LCNet.yml --input=demo/ILSVRC2012_val_00020010.jpeg --output_dir="$OUT"
test -s "$OUT/clas_output.json"
test -s "$OUT/ILSVRC2012_val_00020010.jpeg"
python - "$OUT/clas_output.json" <<'P'
import json,sys
d=json.load(open(sys.argv[1]))
assert len(d)==1, d
r=d[0]
g=lambda k:[v for kk,v in r.items() if kk.split('.')[-1]==k][0]
ids=g('class_ids'); sc=g('scores'); names=g('label_names')
assert len(ids)==5 and len(sc)==5 and len(names)==5, r
assert all(0<=s<=1 for s in sc) and sc==sorted(sc,reverse=True) and sc[0]>0.05, sc
assert all(isinstance(n,str) and n for n in names), names
print(r)
P
echo "ORACLE PASS"
