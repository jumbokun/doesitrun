#!/usr/bin/env bash
# Reproducible CPU setup for PaddleDetection PicoDet inference.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work

# System libs needed by opencv-python (libGL / glib)
apt-get update -qq
apt-get install -y -qq libgl1 libglib2.0-0t64

# Clone
if [ ! -d /work/PaddleDetection/.git ]; then
  git clone --depth 1 https://github.com/PaddlePaddle/PaddleDetection /work/PaddleDetection
fi
cd /work/PaddleDetection

# Python 3.10 venv (README supports <=3.10; system python is 3.12)
[ -x /work/venv/bin/python ] || uv venv -p 3.10 /work/venv
. /work/venv/bin/activate

# paddlepaddle==2.3.2 (README) is no longer published; 2.6.2 is the oldest available CPU build
uv pip install paddlepaddle==2.6.2
uv pip install -r requirements.txt
# setuptools>=81 removed pkg_resources, which ppdet/model_zoo imports
uv pip install "setuptools<80"
uv pip install -e .

# Code patches
python - <<'PY'
p = 'ppdet/data/source/dataset.py'
s = open(p).read()
old = """        anno_file = self.get_anno()
        coco = COCO(anno_file)
        for image in images:"""
new = """        if do_eval:
            anno_file = self.get_anno()
            coco = COCO(anno_file)
        for image in images:"""
if old in s:
    open(p, 'w').write(s.replace(old, new))
p = 'ppdet/utils/visualizer.py'
s = open(p).read()
old = 'get_path(font_url, "~/.cache/paddle/")'
new = 'get_path(font_url, os.path.expanduser("~/.cache/paddle/"))'
if old in s:
    open(p, 'w').write(s.replace(old, new))
PY
grep -q '^import os' ppdet/utils/visualizer.py || sed -i '0,/^import /s//import os\nimport /' ppdet/utils/visualizer.py

# Pre-download weights and visualization font into the caches ppdet uses
mkdir -p /root/.cache/paddle/weights
[ -s /root/.cache/paddle/weights/picodet_s_320_coco_lcnet.pdparams ] || \
  curl -fL --retry 5 -o /root/.cache/paddle/weights/picodet_s_320_coco_lcnet.pdparams \
    https://paddledet.bj.bcebos.com/models/picodet_s_320_coco_lcnet.pdparams
[ -s /root/.cache/paddle/simfang.ttf ] || \
  curl -fL --retry 5 -o /root/.cache/paddle/simfang.ttf https://paddledet.bj.bcebos.com/simfang.ttf

python -c "import paddle, ppdet; print('paddle', paddle.__version__)"
