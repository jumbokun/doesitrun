# MedicalNet CPU ci_test notes

What broke following the README:
- README says Python 3.7 / PyTorch 0.4.1, but requirements.txt pins `torch>=2.6.0` together with
  `numpy==1.15.4`, `scipy==1.1.0`, `nibabel==2.4.1` — unsatisfiable together (and numpy 1.15 can't build
  on modern Python). Python 3.7 isn't available via uv either.
- With modern nibabel (5.x), `img.get_data()` raises ExpiredDeprecationError.
- `scipy.ndimage.interpolation.zoom` is a deprecated namespace in modern scipy.

What I did (see /work/setup.sh):
- uv venv with Python 3.11; torch 2.6.0 CPU wheel; numpy 2.2.6, nibabel 5.5.0, scipy 1.17.1.
- Patched `datasets/brains18.py`: `x.get_data()` -> `np.asanyarray(x.dataobj)`.
- Patched `datasets/brains18.py`, `train.py`, `test.py`: `ndimage.interpolation.zoom` -> `ndimage.zoom`.
- No pretrained weights needed (ci_test sets pretrain_path='').

Result: `python train.py --ci_test` logs `Batch: 0-0 (0), loss = ~2.9` and prints `Finished training`, exit 0.
