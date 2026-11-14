set -e
source /work/env.sh
cd /work/weathernext
test -f weathernext/weathernext2/configs/WeatherNextCyclones_Mini.json   # config ships in the repo (setup.py package_data)
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
B=https://storage.googleapis.com/dm_graphcast/weathernext2
# Same public objects the notebook reads anonymously (docs/weathernext2/wn2_demo.ipynb, cell "Load the weights, params and data").
# steps-04 (one of the notebook's listed choices) so the rollout really feeds predictions back for 4 steps.
timeout 1200 curl -fsSL --retry 3 -o "$OUT/data.nc" "$B/dataset/source-hres_forecast_init-2024-10-07%2000%3A00%3A00_res-1.0_levels-13_steps-04.nc"
timeout 1200 curl -fsSL --retry 3 -o "$OUT/w.npz" "$B/params/WeatherNextCyclones_Mini_%3C2024.npz"
[ "$(stat -c %s "$OUT/w.npz")" -gt 200000000 ]
cat > "$OUT/run_wn.py" <<'PY'
# Core flow of docs/weathernext2/wn2_demo.ipynb cells 8, 11, 12, 16 (plotting / tracker / IBTrACS cells omitted).
import dataclasses, sys
import haiku as hk
import jax
import numpy as np
import xarray
import xarray_jax
from weathernext.utils import rollout, checkpoint, data_utils, fiddle_config_io
from weathernext.weathernext2 import fgn

data_path, weights_path, out_path = sys.argv[1:4]
example_batch = xarray.load_dataset(data_path).compute()
config = fiddle_config_io.get_fiddle_config_by_name("weathernext2/configs/WeatherNextCyclones_Mini")
with open(weights_path, "rb") as f:
    ckpt = checkpoint.load(f, fgn.CheckPoint)

T = example_batch.sizes["time"]
eval_inputs, eval_targets, eval_forcings = data_utils.extract_inputs_targets_forcings(
    example_batch, target_lead_times=slice("6h", f"{(T - 2) * 6}h"),
    **dataclasses.asdict(config.task))
print("eval targets", dict(eval_targets.sizes))

tk = config.predictor_kwargs["noisy_function_kwargs"]["mesh_model_ctor"].keywords["transformer_kwargs"]
# Default splash_mha is a Pallas TPU kernel; the notebook switches to triblockdiag_mha off-TPU (cell 12).
if jax.default_backend() != "tpu":
    tk["attention_type"] = "triblockdiag_mha"

config_inference = fgn.PredictorConfig(
    task=config.task, predictor_constructor=config.predictor_constructor,
    predictor_kwargs=config.predictor_kwargs, predictor_wrappers=config.predictor_wrappers[:-1])

@hk.transform
def run_forward(inputs, targets_template, forcings):
    return fgn.construct_predictor(config_inference)(inputs, targets_template=targets_template, forcings=forcings)

run_forward_jitted = jax.jit(lambda rng, i, t, f: run_forward.apply(ckpt.params, rng, i, t, f))
run_forward_pmap = xarray_jax.pmap(run_forward_jitted, dim="sample")

n = 2 * len(jax.local_devices())
rng = jax.random.PRNGKey(0)
rngs = np.stack([jax.random.fold_in(rng, i) for i in range(n)], axis=0)
chunks = list(rollout.chunked_prediction_generator_multiple_runs(
    predictor_fn=run_forward_pmap, rngs=rngs, inputs=eval_inputs,
    targets_template=eval_targets * np.nan, forcings=eval_forcings,
    num_steps_per_chunk=1, num_samples=n, pmap_devices=jax.local_devices()))
pred = xarray.combine_by_coords(chunks)
print("pred dims", dict(pred.sizes))
assert pred.sizes["sample"] == n, pred.sizes
assert pred.sizes["time"] == eval_targets.sizes["time"] >= 2, (pred.sizes, eval_targets.sizes)

t2 = pred["2m_temperature"]
v = np.asarray(t2.values)
assert np.isfinite(v).all(), "non-finite 2m_temperature"
print("t2m min/max", float(v.min()), float(v.max()))
assert 170.0 < v.min() and v.max() < 345.0, "implausible 2m temperature (K)"
spread = float(t2.std("sample").mean())
print("ensemble spread", spread)
assert spread > 1e-3, "ensemble members identical"
# Skill sanity: first 6h step against the sample's own HRES target (notebook plots this diff in cell 20).
tgt = eval_targets["2m_temperature"].isel(time=0).astype("float64")
mean0 = t2.mean("sample").isel(time=0).astype("float64")
diff = np.asarray((mean0 - tgt).transpose(*tgt.dims).values)   # xarray aligns dims/coords
mask = np.isfinite(diff)
if mask.mean() > 0.5:   # skip if the sample's targets are mostly NaN
    rmse = float(np.sqrt(np.mean(diff[mask] ** 2)))
    print("t2m 6h RMSE vs target", rmse)
    assert rmse < 6.0, "6h forecast far from target: broken model/weights"
pred.to_netcdf(out_path)
print("WROTE", out_path)
PY
cd "$OUT"
timeout 3000 python "$OUT/run_wn.py" "$OUT/data.nc" "$OUT/w.npz" "$OUT/pred.nc" 2>&1 | tee "$OUT/log.txt"
grep -q "^WROTE" "$OUT/log.txt"
[ "$(stat -c %s "$OUT/pred.nc")" -gt 100000 ]
echo ORACLE PASS
