set -e
source /work/env.sh
cd /work/garak
O=$(mktemp -d /tmp/garak_out.XXXX)
timeout 900 python -m garak --list_probes > $O/probes.txt 2>&1
grep -q "probes: test" $O/probes.txt || grep -q "encoding" $O/probes.txt
timeout 1500 python -m garak -t test.Repeat -p test.Test -d always.Pass --report_prefix $O/run > $O/run.log 2>&1 || { tail -30 $O/run.log; exit 1; }
R=$(ls $O/run*.report.jsonl | head -1)
test -s "$R"
grep -q '"entry_type": "attempt"' "$R"
grep -q '"probe_classname": "test.Test"' "$R" || grep -q 'test.Test' "$R"
grep -q "always.Pass" "$R"
ls $O/run*.report.html >/dev/null 2>&1 || true
echo ORACLE PASS
