# Protenix on CPU — notes

README path (`pip install protenix` / `pip install -e .`, then `protenix pred ...`) does not work as written on a CPU-only host.

What broke / what I changed:
1. **GPU-only deps**: requirements.txt pins CUDA torch 2.7.1, cuequivariance(-ops-torch-cu12), triton, deepspeed. Installed torch/torchvision/torchaudio 2.7.1 from the PyTorch CPU index and left out cuequivariance*, triton and deepspeed (inference doesn't need them once torch kernels are used). The rest of requirements.txt is installed as pinned, then `pip install --no-deps -e .`.
2. **Python headers**: scikit-learn-extra 0.3.0 builds from source and needs Python.h, which system python3 here doesn't have. Used a uv-managed Python 3.12 venv (/work/venv), which includes the headers. (sklearn_extra still won't import against numpy 2.4, but Protenix never imports it.)
3. **Fused LayerNorm CUDA kernel**: it's JIT-compiled on import by default (`LAYERNORM_TYPE=fast_layernorm`), which fails on CPU (needs ninja/CUDA). Patched `protenix/model/triangular/layers.py` so the default is `torch` when CUDA isn't available, and env.sh also exports `LAYERNORM_TYPE=torch` (documented in docs/kernels.md).
4. **Triangle kernels**: the CLI defaults to `cuequivariance` for triangle attention and multiplication, so the command crashes with ModuleNotFoundError (and still exits 0). Patched `update_gpu_compatible_configs` in `runner/inference.py` to force the `torch` kernels when there's no CUDA device. The target command now works without extra flags.
5. Weights (~1.4 GB) download automatically to `~/checkpoint` and CCD data to `~/common`. setup.sh fetches them ahead of time with a warm-up prediction on ubiquitin (76 aa): pLDDT about 76, pTM about 0.72, 602 atoms, about 25 s per seed on 4 CPUs.

Caveat: the ~800-residue examples/input.json gets OOM-killed with 15 GB RAM on CPU. Small proteins are fine.
