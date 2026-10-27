set -e
source /work/env.sh
cd /work/PaddleSeg
O=$(mktemp -d /tmp/oracle.XXXXXX)
if [ ! -f data/optic_disc_seg/train_list.txt ]; then
  mkdir -p data && cd data
  wget -q https://paddleseg.bj.bcebos.com/dataset/optic_disc_seg.zip
  unzip -q -o optic_disc_seg.zip
  cd ..
fi
export CUDA_VISIBLE_DEVICES=""
timeout 2400 python tools/train.py \
  --config configs/quick_start/pp_liteseg_optic_disc_512x512_1k.yml \
  --iters 20 --batch_size 2 --save_interval 20 --num_workers 0 \
  --save_dir $O/out
test -s $O/out/iter_20/model.pdparams
timeout 1200 python tools/predict.py \
  --config configs/quick_start/pp_liteseg_optic_disc_512x512_1k.yml \
  --model_path $O/out/iter_20/model.pdparams \
  --image_path data/optic_disc_seg/JPEGImages/H0002.jpg \
  --save_dir $O/result
python - "$O/result" <<'P'
import sys,glob,os
fs=[f for f in glob.glob(sys.argv[1]+'/**/*.png',recursive=True)]
assert fs, "no output pngs"
assert all(os.path.getsize(f)>200 for f in fs), "tiny output"
from PIL import Image
for f in fs:
    w,h=Image.open(f).size; assert w>=100 and h>=100
print(fs)
P
echo "ORACLE PASS"
