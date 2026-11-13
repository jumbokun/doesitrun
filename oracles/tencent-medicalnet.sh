set -e
source /work/env.sh
cd /work/MedicalNet
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 1800 python train.py --ci_test > "$OUT/log.txt" 2>&1 || { tail -50 "$OUT/log.txt"; echo "train failed"; exit 1; }
grep -q "Finished training" "$OUT/log.txt" || { tail -30 "$OUT/log.txt"; echo "no finish marker"; exit 1; }
python - "$OUT/log.txt" <<'P'
import re,sys,math
t=open(sys.argv[1],errors='ignore').read()
m=re.findall(r'loss = (nan|inf|-?[0-9.]+(?:e-?\d+)?)',t)
assert m, "no loss lines"
assert all(math.isfinite(float(x)) for x in m), "non-finite loss"
print("losses:",m)
P
echo "ORACLE PASS"
