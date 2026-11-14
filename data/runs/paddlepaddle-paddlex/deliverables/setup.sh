#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
# OpenCV (opencv-contrib-python, pulled in by paddlex[ocr]) needs libGL/glib
apt-get update -qq
apt-get install -y -qq libgl1 libglib2.0-0t64 libgomp1
cd /work
[ -d PaddleX/.git ] || git clone --depth 1 https://github.com/PaddlePaddle/PaddleX /work/PaddleX
[ -x /work/venv/bin/python ] || uv venv -p 3.12 /work/venv
. /work/venv/bin/activate
uv pip install paddlepaddle==3.3.0 --index-url https://www.paddlepaddle.org.cn/packages/stable/cpu/ --extra-index-url https://pypi.org/simple
uv pip install -e "/work/PaddleX[ocr]"
. /work/env.sh
# Warm-up: downloads OCR models + visualization font into ~/.paddlex
mkdir -p /tmp/pdx_warmup
python -c "
from PIL import Image,ImageDraw,ImageFont
im=Image.new('RGB',(900,150),'white');d=ImageDraw.Draw(im)
d.text((30,40),'Hello World from PaddleX',fill='black',font=ImageFont.load_default(size=48))
im.save('/tmp/pdx_warmup/test.png')"
cd /tmp/pdx_warmup
paddlex --pipeline OCR --input /tmp/pdx_warmup/test.png --use_doc_orientation_classify False --use_doc_unwarping False --use_textline_orientation False --save_path /tmp/pdx_warmup/out --device cpu
ls /tmp/pdx_warmup/out
