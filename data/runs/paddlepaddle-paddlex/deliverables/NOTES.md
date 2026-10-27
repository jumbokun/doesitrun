# PaddleX OCR on CPU — notes

Followed README: `pip install paddlepaddle==3.3.0` (CPU index), then PaddleX from the clone (`pip install -e ".[ocr]"`, Python 3.12 venv via uv).

What broke:
- The README OCR command crashed during text detection (PP-OCRv6 det model) with
  `NotImplementedError: ConvertPirAttribute2RuntimeAttribute not support [pir::ArrayAttribute<pir::DoubleAttribute>]`
  from the oneDNN (MKLDNN) executor. PaddleX turns MKLDNN on by default on CPU. Upgrading to paddlepaddle 3.3.1 or 3.4.0 did not fix it.

What I changed:
- Set `PADDLE_PDX_ENABLE_MKLDNN_BYDEFAULT=False` (in env.sh/setup.sh). This is a built-in PaddleX flag that makes it use the plain Paddle CPU run mode. Kept paddlepaddle==3.3.0 as documented.
- Installed `libgl1 libglib2.0-0 libgomp1` with apt as a precaution for OpenCV/Paddle.
- Set `PADDLE_PDX_MODEL_SOURCE=BOS` and `PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True` so downloads are deterministic and skip the connectivity probe.
- setup.sh warms the cache by running the pipeline once on the official demo image. This downloads PP-LCNet/PP-OCRv6 det/rec models and the simfang.ttf font to ~/.paddlex.

Verified: on a generated image, rec_texts = ['Hello World from PaddleX', 'The quick brown fox'], and `*_res.json` plus `*_ocr_res_img.png` were saved.
