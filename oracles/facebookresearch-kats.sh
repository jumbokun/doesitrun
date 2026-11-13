set -e
source /work/env.sh
cd /work/Kats
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/demo.py <<'PY'
import sys, numpy as np, pandas as pd
from kats.consts import TimeSeriesData
from kats.models.prophet import ProphetModel, ProphetParams
from kats.detectors.cusum_detection import CUSUMDetector
from kats.tsfeatures.tsfeatures import TsFeatures
df = pd.read_csv("kats/data/air_passengers.csv", header=0, names=["time","passengers"])
ts = TimeSeriesData(df)
m = ProphetModel(ts, ProphetParams(seasonality_mode='multiplicative'))
m.fit()
f = m.predict(steps=30, freq="MS")
assert len(f) == 30 and f["fcst"].notna().all(), f
assert f["fcst"].mean() > 100, f
f.to_csv(sys.argv[1] + "/fcst.csv")
np.random.seed(10)
d = pd.DataFrame({'time': pd.date_range('2019-01-01','2019-03-01'),
  'increase': np.concatenate([np.random.normal(1,0.2,30), np.random.normal(2,0.2,30)])})
cps = CUSUMDetector(TimeSeriesData(d)).detector()
assert len(cps) >= 1, cps
idx = cps[0].start_time
assert pd.Timestamp('2019-01-20') <= pd.Timestamp(idx) <= pd.Timestamp('2019-02-10'), idx
feats = TsFeatures().transform(ts)
assert isinstance(feats, dict) and len(feats) > 30, len(feats)
print("FEATS", len(feats), "CP", idx)
PY
timeout 1500 python $OUT/demo.py $OUT
test -s $OUT/fcst.csv
echo ORACLE PASS
