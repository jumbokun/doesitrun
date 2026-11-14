# PaddleGAN AnimeGANv2 on CPU — notes

Followed docs/en_US/install.md (install paddlepaddle, `pip install -r requirements.txt`, `pip install -e .`).

What broke / what I changed:
- **Python version**: system Python 3.12 can't satisfy the old pins (opencv-python<=4.6.0.66, librosa==0.8.1, imageio==2.9.0). Used a uv venv with Python 3.10 (`/work/venv`).
- **Paddle version**: the docs' `mirror.baidu.com` index is gone and PyPI has no 2.1–2.5 wheels. Installed `paddlepaddle==2.6.2` (CPU) from PyPI. I also tried 2.4.2, 2.5.2 and 3.0.0; they fail the same way described below.
- **setuptools** must be installed; Paddle imports it at import time and a uv venv doesn't include it. Pinned `setuptools<70`.
- **numpy<2**: the resolver otherwise picks numpy 2.x, which the opencv 4.6 / librosa 0.8 era packages don't support.
- **System libs**: `libgl1` and `libglib2.0-0` are needed for `import cv2` (opencv-python, not headless).
- **Code patch** (`ppgan/apps/animegan_predictor.py`): the predictor runs the generator on the full-resolution image (1280x853) without `no_grad`. On CPU the last 7x7 conv's im2col buffer is about 64·49·832·1280 floats (~13 GB, past int32 indexing). The process got OOM-killed (12 GB limit), and with `no_grad` it segfaulted in `Im2ColFunctor`. The patch wraps inference in `paddle.no_grad()` and downscales the network input to a max side of 768 px (override with `ANIMEGAN_MAX_SIDE`). The existing code already resizes the result back to the original size. The run takes about 10 s with a 5 GB peak. The output is close to the repo's reference `docs/imgs/animeganv2_res.jpg` (mean abs diff 10, versus 36 between the input and the reference).
- setup.sh also pre-downloads `animeganv2_hayao.pdparams` into `~/.cache/ppgan`. The CLI auto-downloads it too, and I checked that this works.

Run: `source /work/env.sh` (activates the venv and cds to /work/PaddleGAN), then
`python applications/tools/animeganv2.py --input_image docs/imgs/animeganv2_test.jpg --output_path out --cpu`. This writes `out/anime.png`.
