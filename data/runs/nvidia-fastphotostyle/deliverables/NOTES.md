# FastPhotoStyle on CPU

The README/TUTORIAL path (Ubuntu 16.04, CUDA 9.1, Anaconda3, pytorch 0.4.0, cupy, pynvrtc,
conda opencv3) can't be followed here. Those versions are obsolete, there's no GPU, and Python is 3.12.

What I did (`setup.sh` is self-contained: it writes the patch script `/work/tools/patch_cpu.py` itself via a heredoc and runs it, and retries clone/apt/pip with long uv timeouts):
- Made a uv venv on Python 3.12 with CPU-only torch 2.5.1 / torchvision 0.20.1, numpy<2.3, scipy, pillow,
  and `opencv-contrib-python-headless` (`cv2.ximgproc.guidedFilter` is needed by `--fast`).
  I skipped cupy, pynvrtc and scikit-umfpack.
- Installed `libgl1` and `libglib2.0-0` via apt (needed by OpenCV).
- `smooth_filter.py` imported cupy/pynvrtc at module load, so I moved those imports inside
  `smooth_local_affine()`. They're only used by GPU post-processing, which `--no_post` skips.
- `demo.py`: `torch.load(..., map_location='cpu')`.
- `process_stylization.py`: `thumbnail()` resizes the image in place before `cw/ch` are read, so an
  image downscaled by the 960px limit was never resized back. I now record the original content size and
  resize the final output to it. I also replaced the deprecated `F.upsample` with `F.interpolate`.
- The bundled `PhotoWCTModels/photo_wct.pth` (33MB) is a real file in git, so no download is needed.

Tested with 200x150 and 1100x1000 PNG inputs: the output matches the content size and is stylized.
