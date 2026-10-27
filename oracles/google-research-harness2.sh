set -e
source /work/env.sh
cd /work/harness2
out=/tmp/oracle_demo_$$
rm -rf "$out"
timeout 1500 harness2-demo --output "$out" --k 2 | tee /tmp/oracle_demo_out.txt
grep -q "Local demo: .* 0 failed" /tmp/oracle_demo_out.txt
test -s "$out/demo.json"
python3 - "$out/demo.json" <<'P'
import json,sys
d=json.load(open(sys.argv[1]))
assert d["failed"]==0, d
assert d["done"]>=1, d
assert d["execution_count"]>0, d
assert d["editor_calls"]>0, d
P
echo ORACLE PASS
