#!/usr/bin/env bash
# Reproduce the WeatherNext (WN2 Cyclones Mini) CPU setup from scratch.
set -euo pipefail
cd /work
[ -d weathernext/.git ] || git clone https://github.com/google-deepmind/weathernext /work/weathernext
git -C weathernext checkout -q f2f2c51
# gdm-xarray-jax v0.1.1 requires Python>=3.12 (setup.py classifiers say 3.10/3.11).
[ -x venv/bin/python ] || uv venv -p 3.12 venv
. venv/bin/activate
LOCK=/work/scripts/requirements.lock
if [ -f "$LOCK" ]; then
  uv pip install -r "$LOCK" ./weathernext
else
  uv pip install ./weathernext
fi
# h5netcdf no longer pulls in h5py; needed to read the sample .nc files.
# google-cloud-storage is used by the notebook to read the public bucket.
uv pip install h5py google-cloud-storage
# Weights + sample data from the public dm_graphcast bucket (anonymous HTTPS).
mkdir -p /work/data
B=https://storage.googleapis.com/dm_graphcast/weathernext2
[ -s "/work/data/WeatherNextCyclones_Mini_<2024.npz" ] || \
  curl -fSL --retry 3 -o "/work/data/WeatherNextCyclones_Mini_<2024.npz" "$B/params/WeatherNextCyclones_Mini_%3C2024.npz"
[ -s /work/data/sample_steps-01.nc ] || \
  curl -fSL --retry 3 -o /work/data/sample_steps-01.nc "$B/dataset/source-hres_forecast_init-2024-10-07%2000:00:00_res-1.0_levels-13_steps-01.nc"
ln -sf sample_steps-01.nc "/work/data/source-hres_forecast_init-2024-10-07 00:00:00_res-1.0_levels-13_steps-01.nc"
python -c "import weathernext, xarray_jax, jax, haiku; print('ok', jax.__version__, jax.default_backend())"
