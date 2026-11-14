# Detectron on CPU: notes

The README/INSTALL path assumes Python 2, a CUDA-enabled Caffe2 built from source and an NVIDIA GPU
("Detectron operators currently do not have CPU implementation"). None of that applies to this box,
so here's what I did instead:

- **Python/Caffe2:** I made a Python 3.8 venv (uv) and installed the `torch==1.7.1+cpu` wheel. That
  wheel still ships `caffe2.python` and a CPU build of the Detectron ops,
  `torch/lib/libcaffe2_detectron_ops.so`, so nothing has to be compiled from source.
- **Dependency pins:** numpy<1.20, protobuf<3.21, matplotlib<3.4, opencv-python-headless<4.6 and
  pyyaml 5.3.1. The pinned `pyyaml==3.12` from requirements.txt is old and I didn't use it.
  pycocotools comes from pip instead of the cocoapi `make install` step.
- **Code patch** (`/work/detectron-cpu.patch`, applied by setup.sh):
  - `detectron/utils/env.py`: if `libcaffe2_detectron_ops_gpu.so` isn't found, fall back to
    `libcaffe2_detectron_ops.so`.
  - `detectron/utils/c2.py`: `CudaDevice()` returns a CPU DeviceOption when there are no CUDA devices.
    The `gpu_0/` name scope stays, so the weights still load.
  - `detectron/utils/env.py`: `yaml_load` uses `yaml.UnsafeLoader`. The cfg stored inside
    `model_final.pkl` contains `!!python/object` tags, and newer PyYAML refuses to load those by default.
- **`make`:** inside a venv, `make` adds `--user`, so I ran `python setup.py develop` directly.
- **Weights:** setup.sh downloads `model_final.pkl` to `/work/models` and pre-populates
  `/tmp/detectron-download-cache`. The `--wts <URL>` form still checks the md5 online.

Result: `infer_simple.py` writes one PDF per demo image, about 0.7–1.3 MB each, at roughly 20 s per image on CPU.
