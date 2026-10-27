# TimesFM 3.0 setup notes

The README's local install path (`uv venv`, `uv pip install -e .[torch]`) worked as written.
Both TimesFM 3.0 examples (univariate and multivariate with covariates) ran on CPU once
`device="cuda"` was changed to `device="cpu"`, as the task asked. Results:
- univariate: forecast (12,), quantiles (12,9), with sensible values (linear trend continued, sine continued)
- multivariate: forecast (3,24), quantiles (3,24,9), all finite

Changes beyond the README (none of these fixed a failure):
- Installed CPU-only torch from the PyTorch CPU wheel index before `-e .[torch]`. This avoids
  pulling multi-GB CUDA wheels on a machine with no GPU.
- setup.sh downloads the `google/timesfm-3.0-pytorch` checkpoint ahead of time into
  HF_HOME=/work/hf_cache. The repo is public, so no token is needed. env.sh activates
  /work/timesfm/.venv and sets HF_HOME.
