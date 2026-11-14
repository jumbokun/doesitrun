#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
[ -d PaddleX/.git ] || git clone --depth 1 https://github.com/PaddlePaddle/PaddleX /work/PaddleX
# OpenCV runtime libs + fonts for result visualization
apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 libgomp1 fonts-dejavu-core
[ -d /work/venv ] || uv venv --seed -p 3.12 /work/venv
source /work/venv/bin/activate
python -m pip install paddlepaddle==3.3.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/
python -m pip install -e "/work/PaddleX[ocr]"
# Pre-download OCR models by running the pipeline once on a sample image
export PADDLE_PDX_MODEL_SOURCE=${PADDLE_PDX_MODEL_SOURCE:-BOS}
# Paddle 3.3.x oneDNN executor crashes on PP-OCRv6 det (ArrayAttribute<DoubleAttribute>); use plain CPU run mode
export PADDLE_PDX_ENABLE_MKLDNN_BYDEFAULT=False
mkdir -p /work/sample
curl -fsSL -o /work/sample/general_ocr_002.png https://paddle-model-ecology.bj.bcebos.com/paddlex/imgs/demo_image/general_ocr_002.png
paddlex --pipeline OCR --input /work/sample/general_ocr_002.png --use_doc_orientation_classify False --use_doc_unwarping False --use_textline_orientation False --save_path /work/sample/output --device cpu
