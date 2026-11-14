# PaddleOCR CPU setup notes

Followed docs/version3.x/paddlepaddle_installation.en.md (`pip install paddlepaddle==3.2.0 -i .../stable/cpu/`)
and installation.en.md (install `paddleocr` from the git repo; installed editable from the /work/PaddleOCR clone)
in a uv-created Python 3.12 venv (/work/venv).

What broke / what I changed:
- `paddleocr ocr` crashed at import: `ImportError: libGL.so.1` (opencv-contrib-python pulled in by paddlex needs
  system GL/glib libs). Fixed with `apt-get install libgl1 libglib2.0-0t64 libgomp1`. The docs don't mention this.
- The README itself has no install commands; it only links to external docs. The real steps are in docs/version3.x/.
- The docs use plain `python -m pip`; Ubuntu 24.04's system Python is externally managed (PEP 668), so I created a venv first.
- Current `main` uses **PP-OCRv6** (PP-OCRv6_medium_det/rec) as the default, not PP-OCRv5. I kept the repo default for
  `paddleocr ocr -i IMG --save_path DIR`. setup.sh also caches PP-OCRv5_server_det/rec, so
  `--ocr_version PP-OCRv5` works offline as well. (On a synthetic test image, PP-OCRv5 dropped spaces between words
  while v6 kept them.)
- Models are cached in /work/paddlex_cache (`PADDLE_PDX_CACHE_HOME`, set in env.sh). setup.sh downloads them up front
  with a warm-up run, which also fetches the simfang.ttf font used for the visualization.
  `PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True` skips the slow model-host connectivity check.

Verify: `source /work/env.sh; paddleocr ocr -i img.png --save_path out/` writes out/img_res.json (with rec_texts) and
out/img_ocr_res_img.png.
