# FaceDetection-DSFD on CPU — notes

README path (Python 3.6, torch 0.3.1, Tesla GPU) can't be followed here: no GPU, and that old stack isn't practical on Ubuntu 24.04 / uv.

What I did:
- Python 3.11 venv (uv) with CPU torch 2.5.1 / torchvision 0.20.1, plus `numpy<2`, opencv-python-headless, matplotlib, scipy, pillow. The README lists no Python deps besides torch/torchvision.
- Downloaded weights with `gdown` (Drive id 1WeXlNYsM6dMP3xQQELI-4gxhwKUQxc3-) to `weights/WIDERFace_DSFD_RES152.pth` (README says only "download to weights/").
- Prefetch torchvision's ImageNet resnet152 weights: `face_ssd.py` calls `resnet152(pretrained=True)` and downloads them before it loads the DSFD checkpoint.
- Code patches (stored inline in setup.sh):
  - `layers/modules/__init__.py`: stop importing `multibox_loss` (it imports `pa_sfd_match`, which doesn't exist in `box_utils.py`, so `import layers` fails as shipped).
  - `demo.py`: `from widerface_val import bbox_vote` runs widerface_val's module-level code (its own argparse rejects `--img_root`, plus `net.cuda()` and loading the WIDER val set). I copied `bbox_vote` into demo.py instead.
  - `demo.py`: CPU fallback (`net.cuda()` only when CUDA is available), `map_location='cpu'`, `torch.no_grad()` in place of `Variable(volatile=True)`.
  - `layers/functions/detection.py`: `Detect` was an old-style `autograd.Function` (modern torch can't call it that way), so it's now a plain callable. Also `scores.dim()==0` became `scores.numel()==0`.
  - `face_ssd.py`: removed `Variable(volatile=True)`. `layers/box_utils.py` nms: no longer uses `index_select(out=...)`, which caused resize-warning spam.

Result: `python demo.py --img_root ./data/worlds-largest-selfie.jpg --save_folder out/` takes about 65 s on 4 CPUs, finds 647 faces and writes `out/face.png` (1200x1200).
