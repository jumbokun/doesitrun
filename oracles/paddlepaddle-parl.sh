set -e
source /work/env.sh
cd /work/PARL
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cp -r examples/QuickStart/. "$OUT/"
rm -f "$OUT/model.ckpt"
cd "$OUT"
timeout 3000 python train.py --max_episodes 1000 > "$OUT/log.txt" 2>&1 || { tail -30 log.txt; exit 1; }
test -s "$OUT/model.ckpt" || { echo "no model.ckpt"; exit 1; }
grep -q "Test reward" log.txt || { echo "no test reward"; exit 1; }
python - "$OUT/log.txt" <<'PY'
import re,sys
r=[float(x) for x in re.findall(r"Test reward: ([0-9.]+)",open(sys.argv[1]).read())]
print("test rewards:",r)
assert len(r)>=10 and max(r)>=100, "agent did not learn"
PY
echo "ORACLE PASS"
