# Bringing-Old-Photos-Back-to-Life — setup notes

Verified command (stages 1-4, 4/4 bundled scratched images restored):

```
source /work/env.sh
cd /work/Bringing-Old-Photos-Back-to-Life
python run.py --input_folder /work/Bringing-Old-Photos-Back-to-Life/test_images/old_w_scratch \
              --output_folder /work/output --GPU 0 --with_scratch
```

`/work/setup.sh` was re-run from scratch into a second prefix (fresh clone, fresh
downloads, fresh venv) and the pipeline passed there too.

## What broke while following the README

1. **`pip install -r requirements.txt` → dlib build failure.** dlib ships no cp312
   wheel, so it compiles; cmake aborted with `Imported target "pybind11::module"
   includes non-existent path "/usr/include/python3.12"`. Fix: `apt-get install
   python3-dev` (the README lists no system packages; the repo's Dockerfile does).
   `libgl1` + `libglib2.0-0` are likewise needed by `opencv-python`.
2. **PySimpleGUI (in requirements.txt) is no longer installable** from PyPI. It is
   only imported by `GUI.py`, which the full pipeline never touches, so it was
   dropped.
3. **Plain `torch` from PyPI cannot drive this GPU.** The RTX 5060 Laptop is
   Blackwell (sm_120), so torch/torchvision are installed from the CUDA 12.8 index
   (`torch==2.11.0+cu128`, `torchvision==0.26.0+cu128`).
4. **Stage 4 (face blending) crashed** with
   `UFuncOutputCastingError: Cannot cast ufunc 'multiply' output from dtype('float64')
   to dtype('uint8')` at `blur_blending_cv2` in
   `Face_Detection/align_warp_back_multiple_dlib.py:219`. Cause: scikit-image >= 0.20
   keeps the input dtype for `warp(..., preserve_range=True)`, so the warped mask is
   now `uint8` instead of `float64` and the in-place `mask *= 255.0` fails.
   Because `run.py` pre-copies the stage-1 images into `final_output/`, the run still
   *looked* successful and `final_output/` still held one file per input — the
   enhanced faces were simply never blended back.
5. **uv timed out** fetching the CUDA wheels with its 30 s default
   (`UV_HTTP_TIMEOUT=600` in setup.sh).

## Changes made

* `Face_Detection/align_warp_back_multiple_dlib.py` and `..._dlib_HR.py`:
  `mask *= 255.0` → `mask = mask.astype(np.float64) * 255.0` (both occurrences per
  file, i.e. `blur_blending` and `blur_blending_cv2`). Applied by `setup.sh` via sed.
* `numpy` pinned to `1.26.4`; this 2020 code expects numpy 1.x semantics.
* Everything else follows the README: the two `sync_batchnorm` copies, the dlib
  68-landmark model, and the `face_checkpoints.zip` / `global_checkpoints.zip`
  GitHub-release downloads.

Not changed: the `FutureWarning: estimate is deprecated` noise from skimage and the
`SyntaxWarning: invalid escape sequence` lines are harmless.
