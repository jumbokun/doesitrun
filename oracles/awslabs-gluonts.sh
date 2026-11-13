set -e
source /work/env.sh
cd /work/gluonts
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
export OUT MPLBACKEND=Agg
timeout 1500 python - <<'PY'
import os, numpy as np, pandas as pd
import matplotlib.pyplot as plt
from gluonts.dataset.pandas import PandasDataset
from gluonts.dataset.split import split
from gluonts.torch import DeepAREstimator
out = os.environ["OUT"]
idx = pd.date_range("1949-01-01", periods=144, freq="MS")
t = np.arange(144)
rng = np.random.default_rng(0)
y = (100 + 2.5*t) * (1 + 0.2*np.sin(2*np.pi*t/12)) + rng.normal(0, 5, 144)
df = pd.DataFrame({"#Passengers": y}, index=idx)
dataset = PandasDataset(df, target="#Passengers")
training_data, test_gen = split(dataset, offset=-36)
test_data = test_gen.generate_instances(prediction_length=12, windows=3)
model = None
for freq in ("M", "ME"):
    try:
        model = DeepAREstimator(prediction_length=12, freq=freq,
            trainer_kwargs={"max_epochs": 2, "accelerator": "cpu"}).train(training_data)
        break
    except Exception as e:
        print("freq", freq, "failed:", e)
assert model is not None
forecasts = list(model.predict(test_data.input))
assert len(forecasts) == 3, len(forecasts)
for f in forecasts:
    assert f.samples.shape[1] == 12, f.samples.shape
    assert np.isfinite(f.samples).all()
    assert f.mean.shape == (12,)
plt.plot(df["1954":], color="black")
for f in forecasts:
    f.plot()
plt.savefig(os.path.join(out, "forecast.png"))
assert os.path.getsize(os.path.join(out, "forecast.png")) > 5000
print("forecasts ok", forecasts[0].samples.shape)
PY
test -s "$OUT/forecast.png"
echo "ORACLE PASS"
