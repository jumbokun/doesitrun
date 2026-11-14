# PaddleX OCR on CPU — notes

Setup: Python 3.12 uv venv at /work/venv, `paddlepaddle==3.3.0` from the Paddle CPU index (as README says), then `pip install -e "/work/PaddleX[ocr]"` from the clone.

What broke / what I changed:
1. `import cv2` failed with `libGL.so.1: cannot open shared object file`, because opencv-contrib-python needs system libs. Fix: `apt-get install libgl1 libglib2.0-0t64 libgomp1`.
2. With paddlepaddle 3.3.0 on CPU, the default oneDNN (MKLDNN) run mode crashes on the PP-OCRv6 det model: `NotImplementedError: ConvertPirAttribute2RuntimeAttribute not support [pir::ArrayAttribute<pir::DoubleAttribute>]`. Fix: `export PADDLE_PDX_ENABLE_MKLDNN_BYDEFAULT=0` (PaddleX's own flag) in env.sh, so it uses the plain Paddle CPU run mode.
3. README only shows `paddlex[base]` from PyPI. I installed the clone in editable mode with the `[ocr]` extra instead, as the task asks.
4. setup.sh runs the README OCR command once as a warm-up. That downloads the models and the simfang.ttf font into ~/.paddlex before the test.

Result: the README OCR command prints `rec_texts: ['Hello World from PaddleX', 'Quick brown fox 2026']` and writes `*_ocr_res_img.png` and `*_res.json` to `--save_path`.
