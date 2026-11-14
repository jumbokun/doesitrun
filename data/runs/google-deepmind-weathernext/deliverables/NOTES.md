# weathernext (WN2 Cyclones Mini) on CPU — notes

Documented path: `pip install` the repo (notebook install cell), then run wn2_demo.ipynb.

What broke / what I changed:
1. **Python version**: `gdm-xarray-jax` v0.1.1 (pinned in setup.py) needs Python >= 3.12, while
   setup.py classifiers advertise 3.10/3.11. Used a uv venv with Python 3.12 (`/work/venv`).
2. **`colabtools` dependency**: setup.py requires `colabtools`; on PyPI that name belongs to an
   unrelated third-party package (v0.0.1), not Google's Colab tooling, and nothing in the repo
   imports it. Removed it from `install_requires` instead of installing it.
3. **h5py missing**: current h5netcdf no longer pulls in h5py, so `xarray.load_dataset(...nc)`
   failed with "No module named 'h5py'". Installed h5py.
4. **google-cloud-storage** (used by the notebook to read the bucket) isn't a dependency;
   installed it. setup.sh also downloads weights + steps-04 sample to `/work/data` over public HTTPS.
5. **Splash attention is TPU-only**: the Mini config uses `splash_mha` (Pallas), which fails on CPU
   with "Only interpret mode is supported on CPU backend". The notebook only switches to
   `triblockdiag_mha` for GPU. I patched `weathernext/utils/sparse_transformer.py` so that
   `Transformer` falls back to `triblockdiag_mha` on any non-TPU backend. The checkpoint loads fine either way.

Verified: 2-member, 4-step ensemble rollout via `rollout.chunked_prediction_generator_multiple_runs`
on CPU takes about 2.5 minutes. t2m stays within 207–317 K and every value is finite. Ensemble spread
is about 0.3 K, the 6h t2m RMSE against the target is 0.73 K, and the NetCDF output was written.
`source /work/env.sh` activates the venv (and sets JAX_PLATFORMS=cpu).
