#!/usr/bin/env bash
set -euxo pipefail
cd /work
export DEBIAN_FRONTEND=noninteractive
# opencv-contrib-python (pulled in by paddlex) needs libGL / glib at import time
apt-get update
apt-get install -y libgl1 libglib2.0-0t64
[ -d PaddleOCR/.git ] || git clone --depth 1 https://github.com/PaddlePaddle/PaddleOCR /work/PaddleOCR
[ -x /work/venv/bin/python ] || uv venv --python 3.12 --seed /work/venv
source /work/venv/bin/activate
python -m pip install --upgrade pip
# documented CPU install (docs/quick_start.en.md)
python -m pip install paddlepaddle==3.2.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/
python -m pip install "paddleocr[all]"
# warm up: downloads default det/rec models (~/.paddlex/official_models) and the visualization font
mkdir -p /tmp/pocr_warmup
python - <<'PY'
import cv2, numpy as np
im = np.full((120, 700, 3), 255, np.uint8)
cv2.putText(im, 'Hello PaddleOCR', (20, 80), cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 0), 4)
cv2.imwrite('/tmp/pocr_warmup/in.png', im)
PY
paddleocr ocr -i /tmp/pocr_warmup/in.png --save_path /tmp/pocr_warmup/out \
  --use_doc_orientation_classify False --use_doc_unwarping False --use_textline_orientation False
grep -q rec_texts /tmp/pocr_warmup/out/in_res.json
