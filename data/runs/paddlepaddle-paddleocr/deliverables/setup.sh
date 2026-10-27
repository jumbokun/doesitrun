#!/usr/bin/env bash
# Reproduces the PaddleOCR CPU setup from scratch. Run as root.
set -euo pipefail
cd /work

# System libs needed by opencv-contrib-python (pulled in by paddlex)
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq libgl1 libglib2.0-0t64 libgomp1

[ -d /work/PaddleOCR/.git ] || git clone --depth 1 https://github.com/PaddlePaddle/PaddleOCR /work/PaddleOCR

[ -x /work/venv/bin/python ] || uv venv -p 3.12 /work/venv
source /work/venv/bin/activate
uv pip install pip
# Documented CPU install of PaddlePaddle + PaddleOCR (from source)
python -m pip install paddlepaddle==3.2.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/
python -m pip install -e /work/PaddleOCR

source /work/env.sh
python -c "import paddle; paddle.utils.run_check()"

# Warm up: download default models (and PP-OCRv5 models + font) via a real run
python - <<'PY'
from PIL import Image, ImageDraw, ImageFont
im = Image.new('RGB', (800, 200), 'white'); d = ImageDraw.Draw(im)
f = ImageFont.load_default(size=48)
d.text((20, 40), 'Hello World Testing', fill='black', font=f)
d.text((20, 110), 'PaddleOCR works fine', fill='black', font=f)
im.save('/tmp/setup_test.png')
PY
rm -rf /tmp/setup_out /tmp/setup_out5
paddleocr ocr -i /tmp/setup_test.png --save_path /tmp/setup_out
paddleocr ocr -i /tmp/setup_test.png --ocr_version PP-OCRv5 --save_path /tmp/setup_out5
grep -q '"rec_texts"' /tmp/setup_out/setup_test_res.json
ls /tmp/setup_out/setup_test_ocr_res_img.png
echo "SETUP OK"
