set -e
source /work/env.sh
cd /work/promptflow
F=examples/flows/standard/conditional-flow-for-if-else
O=$(mktemp -d /tmp/oracle.XXXXXX)
printf '{"question": "What is Prompt flow?"}\n{"question": "Tell me about cats"}\n{"question": "Hello there"}\n' > $O/data.jsonl
timeout 900 pf flow test --flow $F --inputs question="What is Prompt flow?" > $O/test.txt 2>&1 || { cat $O/test.txt; exit 1; }
cat $O/test.txt
grep -Eq "Prompt flow is a suite of development tools|not familiar with your query" $O/test.txt
timeout 1200 pf run create --flow $F --data $O/data.jsonl --name oracle_run_$$ > $O/run.txt 2>&1 || { cat $O/run.txt; exit 1; }
timeout 300 pf run show-details --name oracle_run_$$ --all-results > $O/details.txt 2>&1 || true
timeout 300 pf run show-details --name oracle_run_$$ > $O/details.txt 2>&1
cat $O/details.txt
python - <<P
import glob, json, os, sys
home = os.path.expanduser("~/.promptflow/.runs/oracle_run_$$")
fs = glob.glob(home + "/**/outputs.jsonl", recursive=True) or glob.glob(home + "/**/flow_outputs/output.jsonl", recursive=True)
assert fs, "no outputs file under " + home
rows = [json.loads(l) for l in open(fs[0]) if l.strip()]
assert len(rows) == 3, rows
for r in rows:
    a = r["answer"]
    assert isinstance(a, str) and ("Prompt flow is a suite" in a or "not familiar with your query" in a), r
print("rows ok", len(rows))
P
echo "ORACLE PASS"
