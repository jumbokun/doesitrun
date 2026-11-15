# LaMa inference on an RTX 5060 (sm_120) — what broke and what I changed

Repo pinned at `786f5936b27fb3dacd2b1ad799e4de968ea697e7`.

## Environment (README path does not work at all here)

The README offers torch 1.8 + python 3.6 (virtualenv/conda). That is dead on
this machine for two independent reasons: no python 3.6 in Ubuntu 24.04, and
torch 1.8 has no kernels for Blackwell (sm_120). `requirements.txt` is also
unresolvable on a modern interpreter (`scikit-image==0.17.2`,
`scikit-learn==0.24.2`, `pytorch-lightning==1.2.9`, `albumentations==0.5.2`,
`kornia==0.5.0`, ...).

What I used instead (`/work/setup.sh`, activated by `/work/env.sh`):
- python 3.11 venv at `/work/venv` (uv), `torch==2.8.0+cu128` /
  `torchvision==0.23.0+cu128` from the PyTorch cu128 index — these do carry
  sm_120 kernels.
- Current releases of the other requirements (pinned in `setup.sh`), plus
  `numpy<2` because several files still use removed aliases such as `np.int`.
- Dropped `tensorflow` and `wldhx.yadisk-direct`: the first is only imported by
  `bin/report_from_tb.py`, the second only fetched the Yandex links that the
  README itself declares dead. Inference touches neither.
- `opencv-python-headless` instead of `opencv-python` (no X11 in the container).

## Code fixes (4, all applied by setup.sh)

1. `saicinpainting/training/data/aug.py` — `from albumentations import
   DualIAATransform, to_tuple` + `import imgaug`. albumentations >= 1.0 removed
   the imgaug-backed IAA transforms, so *every* import of
   `training.data.datasets` (and therefore `bin/predict.py`) died with
   `ImportError: cannot import name 'DualIAATransform'`. The file now keeps the
   original classes when an old albumentations is installed, and otherwise
   defines `IAAAffine2`/`IAAPerspective2` on top of the native `A.Affine` /
   `A.Perspective` (same arguments; `mode=` strings mapped to `cv2.BORDER_*`).
   Training-only code, but it must import.
2. `saicinpainting/training/trainers/__init__.py` — `torch.load` now passes
   `weights_only=False`. torch >= 2.6 flipped that default, and the released
   `big-lama/models/best.ckpt` pickles pytorch-lightning objects
   (`ModelCheckpoint`), so loading failed with `UnpicklingError: Weights only
   load failed`.
3. `bin/predict.py` — the current HEAD hardcodes `device = torch.device("cpu")`
   and ignores `device` from `configs/prediction/default.yaml` (which says
   `device: cuda`). Passing `device=cuda` on the command line therefore ran
   silently on the CPU. Changed to `torch.device(predict_config.device)`.
4. `configs/prediction/default.yaml` — `refiner.gpu_ids` defaulted to `0,1`, so
   the optional `refine=True` path crashed with `CUDA error: invalid device
   ordinal` on this single-GPU box. Default is now `0,` (the value the README
   tells single-GPU users to pass).

Nothing else in the repo needed touching: `hydra-core` 1.3 and
`pytorch-lightning` 2.6 run the predictor as-is, and with `predict_only=True`
no evaluator/perceptual-loss weights are constructed.

## Model

`big-lama.zip` from the HuggingFace mirror in the README (the Yandex links are
gone) unpacked to `/work/lama/big-lama`. Unpacked with python's `zipfile`
because `unzip` is not in the image. The optional ADE20k perceptual-loss
encoder (training only) is fetched best-effort into `/work/lama/ade20k/`.

## Verified

```
source /work/env.sh
python3 bin/predict.py model.path=/work/lama/big-lama indir=<dir> outdir=<dir> device=cuda
```
produces `<name>_maskNNN.png` in `outdir` at the input resolution. Checked on
512x683, 64x65, 333x257 (two masks for one image) and 1920x1280 pairs: output
size equals input size, pixels outside the mask are untouched, pixels inside
change. Peak VRAM is well under 1 GB. `refine=True` also works. Running with
`CUDA_VISIBLE_DEVICES=""` now fails with "No CUDA GPUs are available", which
confirms the run really is on the GPU. `setup.sh` was re-run from scratch after
deleting `/work/lama` and `/work/venv`, and the result passed the same checks.
