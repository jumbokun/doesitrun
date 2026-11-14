#!/usr/bin/env bash
# Reproducible CPU setup for google-deepmind/weathernext (WN2 Mini demo flow).
set -euo pipefail
cd /work
[ -d weathernext/.git ] || git clone https://github.com/google-deepmind/weathernext /work/weathernext
cd /work/weathernext

# 1) setup.py lists "colabtools", which on PyPI is an unrelated third-party
#    package (not Google's Colab tooling) and is never imported. Drop it.
sed -i '/"colabtools",/d' setup.py

# 2) The default config uses the Pallas splash attention kernel, which only
#    runs on TPU. On other backends fall back to triblockdiag_mha (what the
#    notebook does for GPU) so the unmodified notebook flow runs on CPU.
python3 - <<'PY'
p = "weathernext/utils/sparse_transformer.py"
s = open(p).read()
marker = "    # Construct mask and deduce block size.\n    mask = adj_mat ** attention_k_hop\n"
patch = ("    # Splash attention is a TPU-only Pallas kernel; fall back elsewhere.\n"
         "    if attention_type == 'splash_mha' and jax.default_backend() != 'tpu':\n"
         "      attention_type = 'triblockdiag_mha'\n\n")
if "TPU-only Pallas kernel" not in s:
  assert marker in s
  s = s.replace(marker, patch + marker, 1)
  open(p, "w").write(s)
PY

# 3) Python env: gdm-xarray-jax v0.1.1 requires Python >= 3.12.
[ -x /work/venv/bin/python ] || uv venv -p 3.12 /work/venv
# h5py: newer h5netcdf no longer pulls it in but needs it to read the .nc sample.
# google-cloud-storage: used by the notebook to read the public bucket anonymously.
VIRTUAL_ENV=/work/venv uv pip install --python /work/venv/bin/python \
  /work/weathernext h5py google-cloud-storage

# 4) Public weights + sample data (anonymous HTTPS access to gs://dm_graphcast).
mkdir -p /work/data
B=https://storage.googleapis.com/dm_graphcast/weathernext2
[ -s /work/data/mini_2024.npz ] || curl -fSL --retry 3 -o /work/data/mini_2024.npz \
  "$B/params/WeatherNextCyclones_Mini_%3C2024.npz"
[ -s /work/data/sample_steps04.nc ] || curl -fSL --retry 3 -o /work/data/sample_steps04.nc \
  "$B/dataset/source-hres_forecast_init-2024-10-07%2000:00:00_res-1.0_levels-13_steps-04.nc"

/work/venv/bin/python -c "import weathernext, xarray_jax, jax, haiku; print('ok', jax.default_backend())"
