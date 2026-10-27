set -e
source /work/env.sh
cd /work/Detectron
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
IN=$OUT/in; mkdir -p $IN
cp demo/17790319373_bd19b24cfc_k.jpg $IN/
timeout 3000 python tools/infer_simple.py \
  --cfg configs/12_2017_baselines/e2e_mask_rcnn_R-101-FPN_2x.yaml \
  --output-dir $OUT/out --image-ext jpg \
  --wts "https://dl.fbaipublicfiles.com/detectron/35861858/12_2017_baselines/e2e_mask_rcnn_R-101-FPN_2x.yaml.02_32_51.SgT4y1cO/output/train/coco_2014_train:coco_2014_valminusminival/generalized_rcnn/model_final.pkl" \
  $IN 2>&1 | tee $OUT/log.txt
F=$(ls $OUT/out/17790319373_bd19b24cfc_k.jpg.* 2>/dev/null | head -1)
[ -n "$F" ] || { echo "no output file"; exit 1; }
S=$(stat -c %s "$F")
[ "$S" -gt 20000 ] || { echo "output too small: $S"; exit 1; }
case "$F" in *.pdf) head -c 4 "$F" | grep -q '%PDF' || { echo "bad pdf"; exit 1; };; esac
echo "ORACLE PASS"
