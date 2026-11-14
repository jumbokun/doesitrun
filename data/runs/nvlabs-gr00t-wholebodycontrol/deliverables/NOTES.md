# motionbricks VQVAE synthetic training on CPU

The README path basically works. `pip install -e .` followed by `python scripts/train_vqvae.py ...` ran to "Training complete." on CPU, and I didn't have to patch any code. Lightning's `accelerator="auto"` falls back to CPU on its own.

Where I deviated, and why:
- **Environment:** conda isn't in the image, so I used `uv venv -p 3.10` (the README asks for Python 3.10) at /work/venv instead of `conda create`.
- **Torch:** I installed the CPU-only torch wheel from download.pytorch.org/whl/cpu. Otherwise `pip install -e .` would pull the multi-GB CUDA build, which is no use without a GPU.
- **Version pins:** I pinned every resolved dependency version in setup.sh so reruns match (torch 2.14.1+cpu, pytorch-lightning 2.6.6, vector-quantize-pytorch 1.34.0, ...). I also pinned the repo commit.
- **Clone:** I cloned with GIT_LFS_SKIP_SMUDGE=1. The repo's .lfsconfig already excludes motionbricks/out/**, and the hparams/skeleton/stats files the training needs are plain git files. The ~2 GB checkpoints aren't needed.
- I also installed `pynput python-xlib`, as the README says.

env.sh activates /work/venv and cd's into the motionbricks directory.
