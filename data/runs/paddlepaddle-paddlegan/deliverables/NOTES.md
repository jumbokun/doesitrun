# PaddleGAN AnimeGANv2 on CPU — notes

Followed docs/en_US/install.md (pip install paddlepaddle; pip install -e .; pip install -r requirements.txt).

What broke / what I changed:
- **Python version**: system Python 3.12 is too new for the pins (librosa==0.8.1, opencv-python<=4.6.0.66, imageio==2.9.0). Used a uv venv with Python 3.10.
- **PaddlePaddle version**: the README says `paddlepaddle` from mirror.baidu.com. I used PyPI's `paddlepaddle==2.6.2` instead, which is the newest 2.x build; the 2.1–2.5 wheels aren't on PyPI.
- **setuptools missing**: `import paddle` needs setuptools, and a uv venv doesn't include it. Installed `setuptools<70`.
- **numpy 2** got resolved, and opencv 4.6 / paddle 2.6 won't work with it. Pinned `numpy<2`.
- **libGL.so.1 missing** for cv2: installed apt `libgl1 libglib2.0-0t64`.
- **Code patch** (`/work/animegan_cpu.patch`, `ppgan/apps/animegan_predictor.py`):
  1. Inference ran without `paddle.no_grad()`, so autograd kept every activation. A 1280x853 image used more than 12 GB of RAM and got OOM-killed. Wrapped the generator call in `no_grad`.
  2. Paddle's CPU conv (im2col) overflows int32 on the last 7x7 conv (64*49*H*W > 2^31) at full resolution and segfaults. This happens in both 2.6.2 and 3.0.0, with or without oneDNN. Input is now downscaled to at most 640*1024 pixels before the network. The output is still resized back to the original size, as before.
- Weights download automatically from paddlegan.bj.bcebos.com (that worked). setup.sh also pre-fetches them into ~/.cache/ppgan.

Result: `python applications/tools/animeganv2.py --input_image docs/imgs/animeganv2_test.jpg --output_path out --cpu` writes `out/anime.png` (1280x853) in about 17 s. It closely matches docs/imgs/animeganv2_res.jpg.
