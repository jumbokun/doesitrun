# WeatherNext 2 (Cyclones Mini) on CPU — notes

Setup: `bash /work/setup.sh`, then `source /work/env.sh`. Smoke test: `python -I /work/scripts/test_rollout.py`
(it runs a 2-member fgn ensemble rollout with `rollout.chunked_prediction_generator_multiple_runs`; takes about 1.5 min on CPU).

What broke and what I changed:
1. **Python version**: `setup.py` lists Python 3.10/3.11, but its dependency `gdm-xarray-jax` (v0.1.1) needs
   Python >= 3.12, so the install fails to resolve on 3.11. I used a Python 3.12 venv made with uv.
2. **Missing h5py**: `h5netcdf` no longer installs `h5py`, so `xarray.load_dataset` on the sample `.nc`
   file fails with `ImportError: No module named 'h5py'`. I installed `h5py`.
3. **Notebook-only deps**: the notebook uses `google.cloud.storage` (anonymous client) and Colab auth. I installed
   `google-cloud-storage`, but setup.sh downloads the weights and sample data with plain anonymous HTTPS
   from `storage.googleapis.com/dm_graphcast/...` into `/work/data`.
4. **CPU attention**: the default `attention_type='splash_mha'` is a Pallas TPU kernel and fails on CPU
   ("Only interpret mode is supported on CPU backend"). I set
   `transformer_kwargs['attention_type']='triblockdiag_mha'`. The notebook only does this when the backend is GPU, so on CPU you have to set it yourself.
5. To make the install reproducible, I pinned the resolved versions in `scripts/requirements.lock` (jax 0.12.0.1,
   xarray 2026.2.0, numpy 2.5.4, ...) and checked out repo commit f2f2c51.

Result: 2-member ensemble, 2m_temperature ranges 209–315 K, all values finite, mean ensemble std of about 0.25 K.
