# coreai-optimization setup notes (CPU only)

Path followed: README "pip install coreai-opt" (PyPI release 0.4.0) in a uv venv (Python 3.12), then the README Usage snippet.

What broke / what I changed:
1. `pip install coreai-opt` pulled the default torch (CUDA build, latest 2.15). Installed CPU torch from
   https://download.pytorch.org/whl/cpu instead (no GPU here).
2. torch 2.15 triggers `UntestedTorchVersionWarning` (coreai-opt tested up to 2.14), and coreai-torch is validated with torch<=2.13,
   so I pinned torch to 2.13.x (CPU). torchao 0.18.0+cpu is used.
3. `quantizer.finalize()` fails with `ImportError: coreai-torch package is required for MLIR export`.
   The README's plain install does not include it; installed the `[coreai]` extra (`coreai-opt[coreai]` ->
   coreai-torch 0.4.3, coreai-core 1.0.0b3), which is not mentioned in the README.

Result: prepare() and finalize() succeed; prepared model output is (1,10), finite, max abs diff ~2e-3 vs float model.
Remaining harmless warnings: coreai-torch "validated with torch<=2.13.0; found 2.13.0+cpu" (the local version tag
compares higher), plus torch/torchao deprecation warnings.

Files: /work/setup.sh (clone + venv at /work/venv + installs), /work/env.sh (activates /work/venv).
