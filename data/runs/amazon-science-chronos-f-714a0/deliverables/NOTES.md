# Notes
- README says `pip install chronos-forecasting` (PyPI); the task needed the repo clone, so I installed it with `uv pip install -e /work/chronos-forecasting` into a uv venv (/work/venv, Python 3.12).
- CPU only: I installed torch from the PyTorch CPU wheel index so the multi-GB CUDA wheels aren't pulled in. The README example uses `device_map="cuda"`; on this machine it has to be `device_map="cpu"`.
- I installed `pandas[pyarrow]` separately (the README mentions this in a code comment).
- setup.sh pre-downloads amazon/chronos-2 into HF_HOME=/work/hf_cache, and env.sh exports that path.
- The README electricity_price example works on CPU without any code changes (24 rows; columns predictions, 0.1, 0.5, 0.9).
- Heads-up: predict_df defaults to `id_column="item_id"`, so you have to pass `id_column="id"` for DataFrames that use `id`, as the README does.
