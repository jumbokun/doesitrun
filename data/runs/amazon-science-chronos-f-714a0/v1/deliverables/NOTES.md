# chronos-forecasting setup notes (CPU)
- The README path (`pip install chronos-forecasting` + `pandas[pyarrow]`) works fine; no code patches needed.
- Changes/additions:
  - Installed from the local clone (`uv pip install -e`) into a uv venv (/work/.venv, Python 3.12) instead of from PyPI, as the task requires.
  - Installed the CPU-only torch wheel from download.pytorch.org/whl/cpu, which avoids pulling GBs of CUDA wheels on a machine with no GPU.
  - Used `device_map="cpu"` instead of the README's `"cuda"`.
  - Pre-downloaded amazon/chronos-2 into HF_HOME=/work/hf_cache (set in env.sh).
- Gotcha: `predict_df` defaults to `id_column="item_id"`, so with an `id` column you must pass `id_column="id"` (the README example does this).
- Verified: the README electricity_price example gives a (24,7) frame with columns predictions/0.1/0.5/0.9; a synthetic 5-series run gives finite values with ordered quantiles.
