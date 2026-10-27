# NVIDIA/warp setup notes

The README's install path (`pip install warp-lang[examples]`) worked as written on CPU-only Ubuntu 24.04 / Python 3.12.
Installed warp-lang 1.18.0 + usd-core 26.11 from PyPI into a uv venv at /work/.venv. `env.sh` activates it.

- With no GPU, Warp prints a "Could not find CUDA driver" warning and falls back to the "cpu" device (expected).
- `example_mesh --device cpu --num-frames 20` wrote a USD file with 20 time samples per animated attribute.
- A custom `wp.kernel` launched on the CPU and gave correct results. Kernels must be defined in a file;
  `python -c` / `exec()` is not supported because Warp reads the kernel source with `inspect`.
- The only step not in the README: I created a venv (uv) because the system Python is externally managed (PEP 668).
