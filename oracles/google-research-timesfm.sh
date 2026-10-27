set -e
source /work/env.sh
cd /work/timesfm
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'PY'
import numpy as np
from timesfm3 import TimesFM3Evaluator, ModelConfig
config = ModelConfig(checkpoint_path="google/timesfm-3.0-pytorch", per_core_batch_size=32, device="cpu")
f = TimesFM3Evaluator(config)
ts1 = np.linspace(0, 1, 100).astype(np.float32)
ts2 = np.sin(np.linspace(0, 24, 72)).astype(np.float32)
o = list(f.predict_batch([ts1, ts2], horizon=12, return_quantiles=True, use_symmetric_averaging=False))
print("S1", o[0].forecast.shape, o[0].quantiles.shape)
print("S2", o[1].forecast.shape, o[1].quantiles.shape)
assert o[0].forecast.shape == (12,) and o[0].quantiles.shape == (12, 9)
assert o[1].forecast.shape == (12,) and o[1].quantiles.shape == (12, 9)
for x in o:
    assert np.isfinite(x.forecast).all() and np.isfinite(x.quantiles).all()
assert o[0].forecast.mean() > 0.5, o[0].forecast   # linear ramp 0..1 continues upward
assert np.abs(o[1].forecast).max() < 3
T = np.random.RandomState(0)
tgt = T.randn(3,128).astype(np.float32)
po = T.randn(1,128).astype(np.float32)
pf = T.randn(2,152).astype(np.float32)
m = list(f.predict_batch(contexts=[tgt], horizon=24, past_only_covariates=[po], past_future_covariates=[pf], return_quantiles=True, use_symmetric_averaging=False))
print("MV", m[0].forecast.shape, m[0].quantiles.shape)
assert m[0].forecast.shape == (3,24) and m[0].quantiles.shape == (3,24,9)
assert np.isfinite(m[0].forecast).all()
print("SCRIPT OK")
PY
timeout 3000 python $OUT/t.py 2>&1 | tee $OUT/log.txt
grep -q "SCRIPT OK" $OUT/log.txt
grep -q "^S1 (12,) (12, 9)" $OUT/log.txt
grep -q "^MV (3, 24) (3, 24, 9)" $OUT/log.txt
echo "ORACLE PASS"
