# SPADE setup notes (CPU only)

## Result: blocked. The pretrained checkpoints can't be downloaded.
- README step "Download the tar of the pretrained models from the Google Drive Folder"
  (file id `12gvlTbMvUcJewQlSEaZdeb2CdOB-b8kQ`, `checkpoints.tar.gz`, about 1 GB) fails:
  Drive returns HTTP 404 "Page Not Found". gdown fails too. Upstream issue #175
  ("Can't download the tar of the pretrained models") is open with no replacement link.
- Searched for mirrors and found none: Hugging Face (models, datasets, spaces, full-text),
  GitHub repos and releases of GauGAN/SPADE forks (all point at the same dead Drive id),
  Kaggle datasets (only Cityscapes SPADE results via SynBoost, no coco_pretrained),
  ModelScope, and archive.org. Wayback has only Drive's "virus scan warning" page.
  The file itself was never archived.
- So `checkpoints/coco_pretrained` can't be created, and test.py with
  `--name coco_pretrained` can't run. I didn't substitute random or unofficial weights.

## What does work
- Python 3.12 venv (uv) with the CPU-only torch 2.14 + torchvision wheels, plus
  `requirements.txt` (dominate, dill, scikit-image). The README says py3.6/torch 1.0, but no code
  changes were needed.
- Synchronized-BatchNorm-PyTorch clone/copy works exactly as the README says.
- Smoke test: I saved a randomly initialized SPADEGenerator in a temp checkpoints dir and ran
  `test.py --dataset_mode coco --dataroot datasets/coco_stuff --gpu_ids -1` on CPU.
  It processed all 8 bundled val images and wrote the results (16 PNGs). The pipeline is
  ready if you drop the real `coco_pretrained/latest_net_G.pth` into `checkpoints/`.
  I deleted the temp files afterwards.

## setup.sh
Builds the env and sync_batchnorm, then tries the Drive download (gdown, then a direct
usercontent URL). If the download fails, it exits 1 with a clear error.
