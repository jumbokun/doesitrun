set -e
source /work/env.sh
cd /work/chronos-forecasting
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
export OUT
timeout 1800 python - <<'P'
import os, numpy as np, pandas as pd
from chronos import Chronos2Pipeline
rng = np.random.default_rng(0)
rows = []
for sid in ["a", "b", "c"]:
    ts = pd.date_range("2024-01-01", periods=300, freq="h")
    y = 10 + 3*np.sin(np.arange(300)*2*np.pi/24) + rng.normal(0, .3, 300) + (5 if sid == "b" else 0)
    rows.append(pd.DataFrame({"id": sid, "timestamp": ts, "target": y}))
df = pd.concat(rows, ignore_index=True)
pipe = Chronos2Pipeline.from_pretrained("amazon/chronos-2", device_map="cpu")
pred = pipe.predict_df(df, prediction_length=24, quantile_levels=[0.1, 0.5, 0.9],
                       id_column="id", timestamp_column="timestamp", target="target")
pred.to_csv(os.environ["OUT"] + "/pred.csv", index=False)
print(pred.head())
assert len(pred) == 3 * 24, len(pred)
for c in ["id", "timestamp", "predictions", "0.1", "0.5", "0.9"]:
    assert c in pred.columns, (c, list(pred.columns))
v = pred[["0.1", "0.5", "0.9"]].to_numpy(float)
assert np.isfinite(v).all()
assert (v[:, 0] <= v[:, 1] + 1e-6).all() and (v[:, 1] <= v[:, 2] + 1e-6).all()
m = pred[pred.id == "b"]["0.5"].mean()
assert 11 < m < 19, m
assert pred.timestamp.min() > df.timestamp.max()
P
test -s "$OUT/pred.csv"
echo "ORACLE PASS"
