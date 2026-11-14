# PaddleClas (CPU) setup notes

Followed docs/*/deployment whl guide: `pip install paddlepaddle` + `pip install -v -e .` in the repo.

What broke and what I changed:
1. **Python version**: requirements.txt pins `numpy==1.24.4` for Python <3.13; no wheel for 3.12 and the sdist build fails (no distutils). Used Python 3.11 via `uv venv -p 3.11`.
2. **Paddle version**: latest paddlepaddle (3.3.1) makes `deploy/utils/predictor.py` load `inference.json`, but the downloaded ResNet50 inference model is in 2.x `.pdmodel` format -> NotFound. Pinned `paddlepaddle==2.6.2`.
3. **System packages**: opencv-python needs `libgl1` and `libglib2.0-0t64` (ImportError libGL.so.1).
4. **setuptools**: uv venvs ship without setuptools and paddle imports it at import time; installed it.
5. **Code patch** (`__init__.py`): with the editable install the repo root becomes package `paddleclas`, but `ppcls/*` uses absolute `import ppcls...` -> ModuleNotFoundError. Appended the package dir to `sys.path` in `__init__.py`.
6. **cwd shadowing**: running `python` from /work/PaddleClas imports the repo-root `paddleclas.py` as a top-level module (relative-import error). `env.sh` sets `PYTHONSAFEPATH=1`.
7. Doc error: the Python example uses `docs/images/deployment/whl_demo.jpg`; the actual path is `docs/images/inference_deployment/whl_demo.jpg`.

Result: CLI and `PaddleClas(model_name='ResNet50').predict(...)` both give class 8 'hen' at 0.97968.
