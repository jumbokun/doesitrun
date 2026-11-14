# MedicalNet `train.py --ci_test` on CPU

What broke following the README (`Python 3.7.0`, `pip install -r requirements.txt`):
- Python 3.7 is not available via uv on Ubuntu 24.04, and requirements.txt is self-contradictory anyway:
  `torch>=2.6.0` (needs Python >=3.9) alongside `numpy==1.15.4`, `scipy==1.1.0`, `nibabel==2.4.1`
  (ancient; numpy 1.15.4 fails to build on modern Python - needs distutils.msvccompiler).
- With modern nibabel (5.x), `img.get_data()` in datasets/brains18.py raises ExpiredDeprecationError.

What I changed (no code patches):
- Python 3.11 venv at /work/venv (uv).
- torch==2.6.0 CPU wheel from download.pytorch.org/whl/cpu (no GPU).
- numpy==1.26.4, scipy==1.13.1, nibabel==4.0.2 (last series where get_data() still works, only warns).
- `argparse` from requirements dropped (stdlib).
- No pretrained weights needed: --ci_test sets pretrain_path='' and no_cuda=True.

Result: one epoch, 1 batch, `loss = 2.888`, prints `Finished training`, exit 0 (~6 s on CPU).
