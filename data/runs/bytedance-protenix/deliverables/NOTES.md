# Protenix on CPU: notes

The README path is `pip install protenix`, then `protenix pred ...`. On this CPU-only box it did not work as written:

1. **Python.h missing**: `scikit-learn-extra==0.3.0` has no wheel for Python 3.12, so it builds from source, and that needs `python3-dev`. Fix: `apt-get install python3-dev`.
2. **CUDA torch**: `torch==2.7.1` is pinned. I installed the CPU build (`--index-url https://download.pytorch.org/whl/cpu`) first, then `uv pip install -e /work/Protenix` into a uv venv (Python 3.12). The cuequivariance/triton packages still get installed, but nothing imports them when the torch kernels are selected.
3. **Fused LayerNorm needs CUDA**: importing the model JIT-compiles a CUDA layer-norm extension, which fails with `CUDA_HOME environment variable is not set`. Fix: `export LAYERNORM_TYPE=torch`. This is documented in docs/kernels.md but not in the README; it's set in env.sh.
4. Checkpoint and CCD data (about 2 GB) download automatically to `$HOME` (`PROTENIX_ROOT_DIR`). setup.sh pre-fetches them with a warm-up prediction.

I made no code patches. A 76-residue ubiquitin prediction took about 40 s on 4 CPUs once the files were downloaded, with pLDDT about 76 and CA–CA distances between 3.66 and 3.84 Å.
