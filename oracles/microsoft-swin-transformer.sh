set -e
source /work/env.sh
cd /work/Swin-Transformer
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
python - "$OUT" <<'PY'
import sys, os, numpy as np
from PIL import Image
root = sys.argv[1]
rng = np.random.default_rng(0)
for split in ("train", "val"):
    for c in range(4):
        d = os.path.join(root, "imagenet", split, f"class{c}")
        os.makedirs(d, exist_ok=True)
        for i in range(4):
            Image.fromarray(rng.integers(0, 255, (256, 256, 3), dtype=np.uint8)).save(f"{d}/img{i}.jpeg")
PY
CK=$OUT/swin_tiny_patch4_window7_224.pth
curl -fsSL --retry 3 -o $CK https://github.com/SwinTransformer/storage/releases/download/v1.0.0/swin_tiny_patch4_window7_224.pth
test $(stat -c %s $CK) -gt 100000000
timeout 3000 python -m torch.distributed.run --nproc_per_node 1 --master_port 12399 main.py --eval \
  --cfg configs/swin/swin_tiny_patch4_window7_224.yaml --resume $CK \
  --data-path $OUT/imagenet --batch-size 8 --output $OUT/out 2>&1 | tee $OUT/log.txt
grep -E "Accuracy of the network on the 16 test images: *[0-9.]+%" $OUT/log.txt
grep -q "Acc@1" $OUT/log.txt
echo "ORACLE PASS"
