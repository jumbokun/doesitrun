# StyleGAN pretrained_example.py on CPU

The README path (`python pretrained_example.py` with Python 3.6 and TF >= 1.10 on a GPU) does not work as written on this machine.

What broke and what I changed:
1. **Python 3.7 is not available**: the image ships Python 3.12, and uv (0.13) no longer offers 3.6/3.7 builds. TF 1.x needs <=3.7, so I installed Python 3.7 with micromamba (conda-forge) into `/work/conda`.
2. **TensorFlow 1.x**: `tensorflow-cpu==1.15.5` doesn't exist on PyPI, so I used `tensorflow==1.15.5`, which also runs on CPU. I pinned `numpy==1.18.5` and `protobuf==3.20.3` because newer versions break TF 1.15. The README gives no requirements file, so I also installed `pillow` and `requests` myself.
3. **Model download is broken**: `dnnlib.util.open_url` saves Google Drive's "Virus scan warning" HTML page instead of the pickle (`UnpicklingError: invalid load key '<'`). I download it with `gdown` (md5 5a20ed46…) and copy it into `stylegan/cache/<md5(url)>_karras2019stylegan-ffhq-1024x1024.pkl`, where `open_url` checks its cache first.
4. **GPU-pinned ops**: `Gs.run` places ops on `/gpu:0`. I patched `dnnlib/tflib/tfutil.py` to add `allow_soft_placement=True`.
5. **NCHW on CPU**: TF's CPU kernels fail with `Conv2DCustomBackpropInputOp only supports NHWC`. The network code runs from source embedded in the pickle, so editing `training/networks_stylegan.py` would have no effect. Instead I added `dnnlib/tflib/cpu_compat.py`, which wraps conv2d, conv2d_transpose, depthwise_conv2d and avg_pool to transpose NCHW to NHWC and back. `network.py`'s `__setstate__` now rewrites the embedded source to use these wrappers before running it, but only when there is no GPU.

Result: the script prints the Gs layer table and writes `results/example.png` (1024x1024 RGB face) in about 10 s on CPU.
`env.sh` puts `/work/conda/bin` on PATH, hides any GPUs and `cd`s into `/work/stylegan`.
