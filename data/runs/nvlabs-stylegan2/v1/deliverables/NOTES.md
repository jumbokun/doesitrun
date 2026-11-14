# StyleGAN2 on CPU only — notes

The README assumes Python 3.6, TF 1.14/1.15, a CUDA 10.0 GPU, and NVCC to build custom ops on the fly. None of that works here (CPU only, Python 3.12 host, CUDA 12.8). So the README path does not work as written.

## What broke / what I changed
1. **Python version**: TF 1.x has no wheels for Python ≥ 3.8, and `uv` no longer provides 3.7. `setup.sh` downloads a static `micromamba` binary, creates a conda-forge Python 3.7 in `/work/py37`, and builds a venv from it at `/work/venv`.
2. **Dependencies**: I installed `tensorflow-cpu==1.15.0`, which is the only TF1 CPU wheel on PyPI (1.15.5 isn't available as `-cpu`). I pinned `numpy==1.16.6`, `protobuf==3.20.3` and `h5py==2.10.0` so they work with TF 1.15. I also used the Dockerfile's pins for scipy, requests and Pillow.
3. **Custom CUDA ops** (`fused_bias_act`, `upfirdn_2d`, default `impl='cuda'`): the default is now `'ref'` (pure TF) when TF is built without CUDA. You can override it with `STYLEGAN2_OPS_IMPL`.
4. **Hard-coded `/gpu:0` device** in `Network.run()`: I added `allow_soft_placement=True` to the session config in `tfutil.py`.
5. **NCHW convolutions**: TF's CPU kernels only support NHWC (`Conv2DCustomBackpropInputOp only supports NHWC`). The network code is stored inside the pickle, so I couldn't edit it there. Instead, the new `dnnlib/tflib/cpu_compat.py` wraps `tf.nn.conv2d` and `tf.nn.conv2d_transpose` to transpose NCHW↔NHWC. It's only active on non-CUDA TF builds and is imported from `dnnlib/tflib/__init__.py`.
6. **Model download**: `gdrive:` already maps to nvlabs-fi-cdn.nvidia.com in this commit, and the download works. The cache directory was relative to the current directory (`.stylegan2-cache`), so I made it configurable with `STYLEGAN2_CACHE_DIR` (`env.sh` sets it to `/work/stylegan2-cache`). `setup.sh` downloads the FFHQ config-f pickle ahead of time.

All repo edits are in one patch that's embedded in `setup.sh` and applied with `git apply`. `env.sh` activates `/work/venv`, puts the repo on `PYTHONPATH`, and hides GPUs.

Verification: seeds 66 and 230 each produce a 1024x1024 RGB face PNG. The run takes about 20 s on 4 CPU cores.
