# coremltools on Linux (CPU)
- README says `pip install coremltools` (dev: 9.1.dev1). Installed that wheel from PyPI into a uv venv (Python 3.12).
- What broke / needed changing:
  - Unpinned scikit-learn (latest) exceeds coremltools' `_SKLEARN_MAX_VERSION = 1.5.1`; the sklearn converter is then silently disabled. Pinned scikit-learn==1.5.2 (version check compares only major.minor, so 1.5.x passes).
  - Torch pinned to 2.8.0 (`_TORCH_MAX_VERSION`), CPU wheel from download.pytorch.org to avoid CUDA downloads.
- "Failed to load _MLModelProxy: No module named 'coremltools.libcoremlpython'" messages are expected on Linux (prediction is macOS-only); conversion and saving work.
- Verified: traced Conv2d+Linear model -> mlprogram .mlpackage with input 'x'; sklearn LinearRegression -> .mlmodel.
