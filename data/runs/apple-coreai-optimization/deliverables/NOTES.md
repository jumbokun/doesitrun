# coreai-optimization on CPU-only Linux

What I followed: the README's `pip install coreai-opt` (via uv, Python 3.12 venv at /work/venv), then the Usage snippet.

What broke:
- `quantizer.prepare(...)` worked, but `quantizer.finalize()` raised
  `ImportError: coreai-torch package is required for MLIR export`. The README never says
  finalize needs the optional `[coreai]` extra (coreai-torch, coreai-core, scikit-learn).

What I changed:
- Installed `coreai-opt[coreai]` instead of plain `coreai-opt`.
- Installed CPU-only torch from the PyTorch CPU index first, so pip doesn't pull the big CUDA build.
- Pinned torch==2.13.0 / torchao==0.18.0. The newest torch (2.15) works, but it warns that it is
  untested by coreai-opt (CI tests up to 2.14) and by coreai-torch (validated up to 2.13).
  coreai-torch still warns about "2.13.0+cpu". That warning is harmless: it is caused by the `+cpu` suffix.

Result: test_usage.py runs prepare and finalize without errors. The prepared model's output is
finite, has shape (1,10), and differs from the float model by at most about 1.8e-3.
