# stylegan2-ada-pytorch on an RTX 5060 (Blackwell, sm_120)

Repo: NVlabs/stylegan2-ada-pytorch @ `d72cc7d` (current main).

## What broke when following the README

The README's stated requirements are **Python 3.7 + PyTorch 1.7.1 + CUDA 11.0**. That stack
cannot be used here at all:

* PyTorch 1.7.1 ships CUDA 11.0/11.1 kernels whose highest arch is `sm_80`. This GPU is
  `sm_120`, so every CUDA call fails ("no kernel image is available for execution on the
  device"), and the on-the-fly NVCC build of `bias_act` / `upfirdn2d` would be told to
  target an arch the bundled toolkit does not know, so the plugins fall back to the slow
  reference path — exactly the failure mode we had to avoid.
* There are no Python 3.7 wheels for anything CUDA 12.8 anyway, and 3.7 is EOL.
* `imageio-ffmpeg==0.4.3` (pinned in the README's pip line) has no wheel for modern Python.

## What I changed

**No source changes to the repository.** The only deviation is the environment:

* Python 3.11 virtualenv (uv) instead of 3.7.
* `torch==2.8.0+cu128` from the PyTorch cu128 index instead of 1.7.1 — the oldest readily
  available PyTorch that emits `sm_120` code, and it matches the sandbox's CUDA 12.8
  toolkit, so `torch.utils.cpp_extension` compiles the plugins cleanly.
* `numpy==1.26.4` (<2): the 2021 code predates the NumPy 2 API break.
* Dropped the `imageio-ffmpeg==0.4.3` pin (unused by `generate.py`); installed 0.6.0.
* `setup.sh` pre-populates dnnlib's URL cache with `metfaces.pkl` and does one warm-up
  `generate.py` run so the plugins are already built in `~/.cache/torch_extensions`.
* `TORCH_CUDA_ARCH_LIST` is deliberately left unset so PyTorch auto-detects the visible
  card's arch. The resulting "TORCH_CUDA_ARCH_LIST is not set" line is a PyTorch info
  warning, not a plugin fallback.

## Verification

`source /work/env.sh && python generate.py --outdir=out --trunc=1 --seeds=85,265 --network=.../metfaces.pkl`
prints `Setting up PyTorch plugin "bias_act_plugin"... Done.` and the same for
`upfirdn2d_plugin`, with zero "Falling back" lines, and writes 1024x1024
`out/seed0085.png` and `out/seed0265.png`.

I also checked the compiled kernels numerically against the repo's own `impl='ref'`
paths: `bias_act` matches for all nine activations (max abs diff <= 1e-6, `--use_fast_math`
noise) and `upfirdn2d` matches bit-exactly for both up- and downsampling, so sm_120 code
generation is correct and not just silently producing garbage.
