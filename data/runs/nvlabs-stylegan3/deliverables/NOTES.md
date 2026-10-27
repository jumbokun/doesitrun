# stylegan3 gen_images.py on CPU

README path: conda `environment.yml` (pytorch 1.9.1 + cudatoolkit 11.1, python>=3.8) and a CUDA GPU. Not usable here (no GPU, no conda).

Problems and fixes:
- `gen_images.py` hard-codes `torch.device('cuda')` -> patched (sed in setup.sh) to fall back to CPU when CUDA is unavailable. The custom ops (bias_act, filtered_lrelu, upfirdn2d) already fall back to their reference implementations on CPU.
- Used a uv venv with Python 3.10 + CPU torch 2.2.2 (from the PyTorch CPU index) and `numpy<2` in place of the conda env pins.
- `torch_utils/ops/conv2d_gradfix.py` (which also gets loaded from the network pickle) imports `pkg_resources`, and a fresh venv doesn't have it -> installed `setuptools<70`.
- Pickle is downloaded ahead of time into `DNNLIB_CACHE_DIR=/work/cache/dnnlib` (set in env.sh), so the README URL resolves from cache.

Verified: `python gen_images.py --outdir=out --trunc=1 --seeds=2 --network=<README URL>` writes out/seed0002.png (512x512 RGB) in about 27 s on 4 CPUs.
