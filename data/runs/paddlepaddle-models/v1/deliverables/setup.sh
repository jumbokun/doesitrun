#!/usr/bin/env bash
# Reproduce paddlecv CPU setup (PP-LCNet classification) from scratch.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work

# System libs: libsndfile1 (documented), libGL/glib for opencv (undocumented)
apt-get update -qq
apt-get install -y -qq libgl1 libglib2.0-0t64 libsndfile1

[ -d /work/models/.git ] || git clone --depth 1 https://github.com/PaddlePaddle/models /work/models

# paddlepaddle 2.x wheels only exist for py<=3.11; 2.3.2 is gone from PyPI and the
# Baidu mirror returns 403, so use the oldest available 2.x (2.6.2) on Python 3.9.
[ -x /work/venv/bin/python ] || uv venv -p 3.9 /work/venv
. /work/venv/bin/activate
cd /work/models/paddlecv
uv pip install paddlepaddle==2.6.2 -r requirements.txt \
    "setuptools<70" pip "numpy<2" \
    "opencv-python<4.11" "opencv-contrib-python<4.11" \
    "aistudio-sdk==0.2.6" paddlenlp==2.8.1 paddlespeech==1.5.0 faiss-cpu==1.7.1.post2

# Smoke test; also downloads the pretrained inference model + label dict to ~/.cache/paddlecv
python -u tools/predict.py --config=configs/single_op/PP-LCNet.yml \
    --input=demo/ILSVRC2012_val_00020010.jpeg --output_dir=/tmp/paddlecv_setup_out
test -f /tmp/paddlecv_setup_out/clas_output.json
echo "setup OK"
