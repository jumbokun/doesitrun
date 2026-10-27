set -e
source /work/env.sh
cd /work/PaddleDetection
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
timeout 1800 python tools/infer.py -c configs/picodet/picodet_s_320_coco_lcnet.yml \
  -o weights=https://paddledet.bj.bcebos.com/models/picodet_s_320_coco_lcnet.pdparams use_gpu=False \
  --infer_img=demo/000000014439.jpg --output_dir="$OUT" 2>&1 | tee "$OUT/log.txt"
IMG="$OUT/000000014439.jpg"
test -f "$IMG"
SZ=$(stat -c %s "$IMG")
[ "$SZ" -gt 10000 ]
grep -qi "class_id\|score\|bbox" "$OUT/log.txt"
cmp -s "$IMG" demo/000000014439.jpg && { echo "output identical to input"; exit 1; }
echo ORACLE PASS
