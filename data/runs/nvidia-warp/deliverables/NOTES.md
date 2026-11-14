# NVIDIA/warp on CPU

Followed the README: `pip install warp-lang[examples]` (PyPI wheel, warp-lang 1.19.0 + usd-core) into a
uv venv at /work/venv (Python 3.12). Nothing broke.

- The mesh example ran on CPU and wrote a time-sampled USD file (time codes 0-20).
- A custom kernel launched on `cpu` and returned correct results. It needs the system C++ toolchain,
  which is already in the image.

What I did beyond the README: I used a venv, because Ubuntu 24.04's system Python is PEP 668
"externally managed" and a plain pip install into it is refused. I also noticed that Warp kernels
can't be defined via `python -c` or `exec()`; the kernel has to live in a file.
