# MNIST (mlx-examples) on CPU

- Following the README (`pip install -r requirements.txt`) on Linux installs only the `mlx` wheel, and
  `import mlx.core` fails with `ImportError: libmlx.so: cannot open shared object file`.
- Fix: also install `mlx[cpu]` (pulls in `mlx-cpu`, which provides the Linux CPU backend). Not in the README.
- Used a uv venv at /work/venv (Python 3.12). `python main.py` then downloads MNIST and trains 10 epochs
  (~2 s/epoch), final test accuracy ~0.95.
