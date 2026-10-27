set -e
source /work/env.sh
cd /work/SkillOpt
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 900 python -m skillopt_sleep.experiments.run_experiment --persona researcher --assert-improves > "$OUT/text.txt" 2>&1
grep -q "PASS: nightly consolidation improves held-out score AND gate blocks regressions" "$OUT/text.txt"
timeout 900 python -m skillopt_sleep.experiments.run_experiment --persona researcher --json > "$OUT/res.json" 2>"$OUT/err.txt"
python - "$OUT/res.json" <<'P'
import json,sys
s=open(sys.argv[1]).read()
r=json.loads(s[s.index('{'):])
assert r["backend"]=="mock", r["backend"]
assert r["n_tasks"]>0 and r["nights_run"]>=1
assert r["after_holdout"]>r["baseline_holdout"]
assert r["improved"] is True and r["gate_blocks_harmful"] is True
assert len(r["trace"])>=2
print("checked", r["baseline_holdout"], "->", r["after_holdout"])
P
echo "ORACLE PASS"
