# Pass: compiled CUDA op importable (the README's '_C not defined' pain) AND GPU demo writes pred.jpg.
set -e
source /work/env.sh
cd /work/GroundingDINO
python -c "from groundingdino import _C; print('ORACLE: _C ok', _C.__file__)"
rm -rf /tmp/oracle_gd
CUDA_VISIBLE_DEVICES=0 timeout 1200 python demo/inference_on_a_image.py \
  -c groundingdino/config/GroundingDINO_SwinT_OGC.py -p weights/groundingdino_swint_ogc.pth \
  -i .asset/cat_dog.jpeg -o /tmp/oracle_gd -t "cat . dog ."
test -s /tmp/oracle_gd/pred.jpg || { echo "ORACLE: no pred.jpg"; exit 1; }
echo "ORACLE PASS"
