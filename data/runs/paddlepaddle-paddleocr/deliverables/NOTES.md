# PaddleOCR on CPU — notes

Followed docs/quick_start.en.md: `pip install paddlepaddle==3.2.0 -i .../stable/cpu/` then
`pip install "paddleocr[all]"` (paddleocr 3.7.0 / paddlex 3.7.2) in a uv venv at /work/venv (Python 3.12).

What broke:
- `import cv2` (opencv-contrib-python, pulled in by paddlex) failed with
  `ImportError: libGL.so.1` on the bare Ubuntu image. Fixed by `apt-get install libgl1 libglib2.0-0t64`.
  The docs don't mention any system packages.

Other things I did that the docs don't cover:
- Created a venv (uv venv --seed) since system pip is externally managed on Ubuntu 24.04.
- setup.sh runs the CLI once on a generated image to pre-download the PP-OCRv6_medium det/rec models
  (~/.paddlex/official_models) and the simfang.ttf visualization font.
- env.sh sets PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True to skip the startup model-host connectivity check
  (optional, it just speeds startup).

Verified: `paddleocr ocr -i img --save_path out --use_doc_orientation_classify False --use_doc_unwarping False
--use_textline_orientation False` writes out/<name>_res.json with the right rec_texts and out/<name>_ocr_res_img.png.
