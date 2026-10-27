#!/usr/bin/env bash
# Reproduces a CPU-only Detectron (Caffe2) inference setup in /work.
set -euo pipefail
W=${WORK_DIR:-/work}
cd "$W"
MODEL_URL="https://dl.fbaipublicfiles.com/detectron/35861858/12_2017_baselines/e2e_mask_rcnn_R-101-FPN_2x.yaml.02_32_51.SgT4y1cO/output/train/coco_2014_train:coco_2014_valminusminival/generalized_rcnn/model_final.pkl"

# 1. Clone
if [ ! -d Detectron/.git ]; then
  git clone https://github.com/facebookresearch/Detectron Detectron
fi
git -C Detectron checkout -q 04155a0

# 2. Python 3.8 venv with PyTorch 1.7.1 CPU wheel (ships caffe2 + libcaffe2_detectron_ops.so)
export UV_PYTHON_INSTALL_DIR="$W/.uv-python"
[ -x venv/bin/python ] || uv venv -p 3.8 venv
source venv/bin/activate
uv pip install "torch==1.7.1+cpu" -f https://download.pytorch.org/whl/torch_stable.html
uv pip install "numpy<1.20" "protobuf<3.21" "pyyaml==5.3.1" "matplotlib<3.4" \
  "opencv-python-headless<4.6" "scipy<1.11" six future mock Cython "setuptools<60" pycocotools

# 3. CPU patches (ops lib fallback, CPU device fallback, unsafe yaml loader)
cd Detectron
if ! grep -q "Fall back to the CPU-only build" detectron/utils/env.py; then
  git apply "$W/detectron-cpu.patch"
fi
python setup.py develop   # equivalent of `make` (which would add --user inside a venv)
cd "$W"

# 4. Weights: keep a copy and pre-populate Detectron's download cache
mkdir -p models
[ -s models/model_final.pkl ] || curl -fL --retry 3 -o models/model_final.pkl "$MODEL_URL"
CACHE=/tmp/detectron-download-cache/${MODEL_URL#https://dl.fbaipublicfiles.com/detectron/}
mkdir -p "$(dirname "$CACHE")"
[ -s "$CACHE" ] || cp models/model_final.pkl "$CACHE"
echo "setup done"
