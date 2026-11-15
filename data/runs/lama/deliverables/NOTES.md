# LaMa inference setup notes

Result: `python3 bin/predict.py model.path=/work/lama/big-lama indir=... outdir=...` works (tested: same-size output,
unmasked pixels identical, masked object removed). Note predict.py hard-codes `device = cpu`, so inference runs on CPU;
the GPU is not used for this path (torch cu128 is installed anyway so CUDA/sm_120 works if needed).

What broke / what I changed:
- README has no Python version or env instructions; requirements.txt pins (scikit-image 0.17.2, scikit-learn 0.24.2)
  don't build on Ubuntu 24.04's Python 3.12. Used a uv venv with Python 3.10 (/work/venv).
- Relaxed pins: scikit-image 0.19.3, scikit-learn 1.3.2, numpy<2 (1.26.4); dropped tensorflow (not used by predict).
  Kept hydra-core 1.1.0, pytorch-lightning 1.2.9, kornia 0.5.0, albumentations 0.5.2. Full lock embedded in setup.sh.
- Torch isn't listed in requirements at all; installed torch 2.7.1 / torchvision 0.22.1 from the cu128 index (Blackwell sm_120 support).
- opencv-python needs libGL/glib: apt install libgl1 libglib2.0-0. `unzip` is not in the base image: apt install unzip.
- PyTorch >= 2.6 defaults `torch.load(weights_only=True)`, which rejects the Lightning checkpoint. Patched
  `saicinpainting/training/trainers/__init__.py` load_checkpoint to pass `weights_only=False` (checkpoint is the official one from README).
- Model download (curl from HuggingFace + unzip) worked as documented.
