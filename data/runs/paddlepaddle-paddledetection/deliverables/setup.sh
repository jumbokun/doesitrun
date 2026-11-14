#!/usr/bin/env bash
# Reproduce PaddleDetection CPU inference setup (picodet_s_320_coco_lcnet).
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work

# System libs needed by opencv-python (libGL / glib)
apt-get update -qq
apt-get install -y -qq libgl1 libglib2.0-0t64

# Clone (pinned to the commit this was tested against)
if [ ! -d PaddleDetection/.git ]; then
  git clone https://github.com/PaddlePaddle/PaddleDetection /work/PaddleDetection
fi
cd /work/PaddleDetection
git checkout -f b25522a0f4bde8c80603f3ba5e3472059972e3b5

# Python 3.10 venv (README lists 3.5-3.10; paddle 2.3.2 no longer published)
[ -d /work/venv ] || uv venv -p 3.10 /work/venv
. /work/venv/bin/activate
uv pip install paddlepaddle==3.0.0
uv pip install -r requirements.txt
# pkg_resources was removed in setuptools>=81, ppdet still imports it
uv pip install "setuptools<81"
uv pip install --no-build-isolation -e .

# Fix: ImageFolder always loaded the COCO annotation file, even for plain inference
python3 - <<'PY'
p = 'ppdet/data/source/dataset.py'
s = open(p).read()
old = """        anno_file = self.get_anno()
        coco = COCO(anno_file)
        for image in images:"""
new = """        coco = None
        if do_eval:
            anno_file = self.get_anno()
            coco = COCO(anno_file)
        for image in images:"""
if old in s:
    open(p, 'w').write(s.replace(old, new))
PY

# Download weights + visualization font into the cache by running the demo once
python tools/infer.py -c configs/picodet/picodet_s_320_coco_lcnet.yml \
  -o use_gpu=False weights=https://paddledet.bj.bcebos.com/models/picodet_s_320_coco_lcnet.pdparams \
  --infer_img=demo/000000014439.jpg --output_dir=output
ls -la output/000000014439.jpg
