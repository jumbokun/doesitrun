set -e
source /work/env.sh
cd /work/qlib
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
if [ ! -d ~/.qlib/qlib_data/cn_data/calendars ]; then
  timeout 1200 python scripts/get_data.py qlib_data --target_dir ~/.qlib/qlib_data/cn_data --region cn
fi
sed -e 's/num_threads: 20/num_threads: 4/' examples/benchmarks/LightGBM/workflow_config_lightgbm_Alpha158.yaml > $OUT/cfg.yaml
mkdir -p $OUT/run && cd $OUT/run
timeout 6000 python -c "
import sys
from qlib.cli.run import run
run()
" $OUT/cfg.yaml > $OUT/log.txt 2>&1 || { tail -50 $OUT/log.txt; echo "qrun failed"; exit 1; }
tail -40 $OUT/log.txt
grep -q "information_ratio\|excess_return_with_cost" $OUT/log.txt || { echo "no backtest analysis in output"; exit 1; }
grep -q "IC" $OUT/log.txt || { echo "no IC in output"; exit 1; }
python - "$OUT" <<'PY'
import sys, glob, pickle, os
out = sys.argv[1]
preds = glob.glob(out + "/run/mlruns/*/*/artifacts/sig_analysis/ic.pkl")
assert preds, "no ic.pkl"
ic = pickle.load(open(preds[0], "rb"))
print("IC mean", ic.mean(), "n", len(ic))
assert len(ic) > 100 and 0.0 < ic.mean() < 0.2
pf = glob.glob(out + "/run/mlruns/*/*/artifacts/portfolio_analysis/report_normal_1day.pkl")
assert pf, "no portfolio report"
r = pickle.load(open(pf[0], "rb"))
assert len(r) > 100
print("report rows", len(r))
PY
echo "ORACLE PASS"
