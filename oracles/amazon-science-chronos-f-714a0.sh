set -e
source /work/env.sh
cd /work/chronos-forecasting
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
export OUT
timeout 1800 python - <<'P'
import os, numpy as np, pandas as pd
from chronos import Chronos2Pipeline
rng = np.random.default_rng(0)
H, N = 24, 300
rows = []
for sid in ["a", "b", "c"]:
    ts = pd.date_range("2024-01-01", periods=N, freq="h")
    y = 10 + 3*np.sin(np.arange(N)*2*np.pi/24) + rng.normal(0, .3, N) + (5 if sid == "b" else 0)
    rows.append(pd.DataFrame({"id": sid, "timestamp": ts, "target": y}))
df = pd.concat(rows, ignore_index=True)
pipe = Chronos2Pipeline.from_pretrained("amazon/chronos-2", device_map="cpu")

def check(pred, n_series, tag):
    print(tag, pred.head())
    assert len(pred) == n_series * H, (tag, len(pred))
    # output columns: src/chronos/chronos2/pipeline.py:955-960
    for c in ["id", "timestamp", "predictions", "0.1", "0.5", "0.9"]:
        assert c in pred.columns, (tag, c, list(pred.columns))
    v = pred[["0.1", "0.5", "0.9"]].to_numpy(float)
    assert np.isfinite(v).all() and np.isfinite(pred["predictions"].to_numpy(float)).all(), tag
    assert (v[:, 0] <= v[:, 1] + 1e-6).all() and (v[:, 1] <= v[:, 2] + 1e-6).all(), tag
    assert (pred.groupby("id").size() == H).all(), tag

# 1. univariate predict_df (README "Forecasting", README.md:86-94)
pred = pipe.predict_df(df, prediction_length=H, quantile_levels=[0.1, 0.5, 0.9],
                       id_column="id", timestamp_column="timestamp", target="target")
pred.to_csv(os.environ["OUT"] + "/pred.csv", index=False)
check(pred, 3, "univariate")
m = pred[pred.id == "b"]["0.5"].mean()
assert 11 < m < 19, m
assert pred.timestamp.min() > df.timestamp.max()

# 2. the README example's other half: past + known-future covariates via future_df
#    (README.md:81-83, 86-88; predict_df docstring pipeline.py:843-849). Synthetic stand-in for the
#    electricity_price parquet so the test does not depend on an external S3 file.
crow, frow = [], []
for sid in ["p", "q"]:
    ts = pd.date_range("2024-03-01", periods=N + H, freq="h")
    cov = (np.arange(N + H) % 24 >= 12).astype(float) * 4.0
    y = 20 + cov + rng.normal(0, .3, N + H)
    crow.append(pd.DataFrame({"id": sid, "timestamp": ts[:N], "target": y[:N], "load": cov[:N]}))
    frow.append(pd.DataFrame({"id": sid, "timestamp": ts[N:], "load": cov[N:]}))
cdf, fdf = pd.concat(crow, ignore_index=True), pd.concat(frow, ignore_index=True)
pred2 = pipe.predict_df(cdf, future_df=fdf, prediction_length=H, quantile_levels=[0.1, 0.5, 0.9],
                        id_column="id", timestamp_column="timestamp", target="target")
pred2.to_csv(os.environ["OUT"] + "/pred_cov.csv", index=False)
check(pred2, 2, "covariates")
m2 = pred2["0.5"].mean()
assert 17 < m2 < 29, m2
assert set(pd.to_datetime(pred2.timestamp)) == set(pd.to_datetime(fdf.timestamp))
P
test -s "$OUT/pred.csv"
test -s "$OUT/pred_cov.csv"
echo "ORACLE PASS"
