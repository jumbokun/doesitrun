# motionbricks (GR00T-WholeBodyControl) – CPU setup notes

The documented path essentially worked; both `train_vqvae.py` and `train_root.py` ran 20 steps on CPU and printed `Training complete.` with no code changes (Lightning `accelerator="auto"` falls back to CPU).

Deviations from the README:
- README says a CUDA GPU is required and uses conda; I used a `uv` Python 3.10 venv (`/work/venv`) and installed the **CPU** torch wheel from download.pytorch.org/whl/cpu to avoid the default CUDA build.
- Pinned the resolved versions (torch 2.14.1, pytorch-lightning 2.6.6, vector-quantize-pytorch 1.34.0, transformers 5.20.2, ...) in setup.sh for reproducibility; setup.py is unpinned.
- Cloned with `GIT_LFS_SKIP_SMUDGE=1`: the synthetic training only needs the yaml/npy/pickle files under `out/`, which are not LFS; checkpoints are not needed.
- `env.sh` activates the venv and cd's into `motionbricks/`.
