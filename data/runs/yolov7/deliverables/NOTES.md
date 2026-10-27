# yolov7 on an RTX 5060 (sm_120) — what broke, what changed

Verified command (from /work/yolov7, after `source /work/env.sh`):

    python detect.py --weights yolov7.pt --conf 0.25 --img-size 640 \
      --source inference/images/horses.jpg --device 0
    -> "5 horses, Done. (20.6ms) Inference" ; annotated runs/detect/exp/horses.jpg

## What broke following the README

1. **The README's install path is a 2021 NGC docker image** (`nvcr.io/nvidia/pytorch:21.08-py3`,
   torch 1.9). Nothing in `requirements.txt` (`torch>=1.7.0`) can drive Blackwell: any
   pre-cu128 wheel aborts with "no kernel image is available for execution on the device"
   for sm_120. Fixed by installing **torch 2.11.0+cu128 / torchvision 0.26.0+cu128** from
   the PyTorch cu128 index into a uv venv on Python 3.11.
2. **`torch.load` refuses the official checkpoint.** torch >= 2.6 defaults to
   `weights_only=True`, and `yolov7.pt` pickles `models.yolo.Model`:
   `UnpicklingError: Unsupported global: GLOBAL models.yolo.Model`.
   Patched the three `torch.load` call sites to pass `weights_only=False`
   (`models/experimental.py` attempt_load — the one the demo hits — plus
   `utils/general.py` strip_optimizer and `utils/datasets.py` cache load).
3. **`libgl1-mesa-glx` is gone on Ubuntu 24.04**, so the README's apt line fails; `import cv2`
   needs libGL anyway. Installed `libgl1` + `libglib2.0-0t64` instead.
4. **numpy must stay on 1.x.** `requirements.txt` says `<1.24`; the repo still calls removed
   numpy-1 APIs (`np.int` in `utils/datasets.py`, `deploy/`). Pinned `numpy==1.26.4`, which
   keeps the numpy-1 API and is what torch 2.11 is happy with. Python 3.11 was chosen because
   it is the newest interpreter with wheels for the whole pinned set.

## Not changed

Model code, cfgs and the demo command are untouched. `torch.meshgrid` emits an indexing
deprecation warning and detect.py re-traces the model on each run (`traced_model.pt`,
~20 s, ~148 MB in the repo root); both are harmless.
