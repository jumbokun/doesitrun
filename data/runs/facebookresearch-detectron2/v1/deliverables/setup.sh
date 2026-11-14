#!/bin/bash
set -euxo pipefail
cd /work
[ -d detectron2 ] || git clone https://github.com/facebookresearch/detectron2 /work/detectron2
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 ninja-build python3-dev
rm -rf /work/venv; uv venv --python 3.12 /work/venv
. /work/venv/bin/activate
uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
uv pip install opencv-python-headless setuptools wheel ninja
# setup.py imports torch, so build isolation must be disabled; force CPU-only build
export FORCE_CUDA=0 CUDA_HOME= TORCH_CUDA_ARCH_LIST=
uv pip install --no-build-isolation -e /work/detectron2
# pre-download checkpoint into fvcore cache and a sample image
mkdir -p /work/models /work/sample
python - <<'PY'
from detectron2.utils.file_io import PathManager
print(PathManager.get_local_path("detectron2://COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x/137849600/model_final_f10217.pkl"))
PY
curl -fsSL -o /work/sample/input.jpg http://images.cocodataset.org/val2017/000000439715.jpg || true
# demo.py has a leaked Meta-internal import path; use the local predictor module
sed -i 's/^from vision\.fair\.detectron2\.demo\.predictor import/from predictor import/' /work/detectron2/demo/demo.py
# create --output as a directory when it doesn't exist and has no file extension
python - /work/detectron2/demo/demo.py <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
old = "            if args.output:\n                if os.path.isdir(args.output):\n                    assert"
new = ("            if args.output:\n"
       "                if not os.path.exists(args.output) and not os.path.splitext(args.output)[1]:\n"
       "                    os.makedirs(args.output, exist_ok=True)\n"
       "                if os.path.isdir(args.output):\n                    assert")
if new not in s:
    assert old in s; s = s.replace(old, new, 1); open(p, "w").write(s)
PY
