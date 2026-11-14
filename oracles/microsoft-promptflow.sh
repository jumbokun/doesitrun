set -e
source /work/env.sh
cd /work/promptflow
F=examples/flows/standard/conditional-flow-for-if-else
O=$(mktemp -d /tmp/oracle.XXXXXX)
# Questions differ from the flow's default ("What is Prompt flow?", flow.dag.yaml:4) so the batch check
# can tell data-driven rows from rows that silently fell back to the default input.
printf '{"question": "Tell me about cats"}\n{"question": "Hello there"}\n{"question": "How do rivers form"}\n{"question": "Name a prime number"}\n{"question": "Why is the sky blue"}\n{"question": "What is a flow run"}\n' > $O/data.jsonl
timeout 900 pf flow test --flow $F --inputs question="What is Prompt flow?" > $O/test.txt 2>&1 || { cat $O/test.txt; exit 1; }
cat $O/test.txt
grep -Eq "Prompt flow is a suite of development tools|not familiar with your query: What is Prompt flow\?" $O/test.txt
# Batch run exactly as the flow README documents it (README.md:45), including the column mapping.
timeout 1200 pf run create --flow $F --data $O/data.jsonl --column-mapping question='${data.question}' --name oracle_run_$$ > $O/run.txt 2>&1 || { cat $O/run.txt; exit 1; }
timeout 300 pf run show-details --name oracle_run_$$ > $O/details.txt 2>&1
cat $O/details.txt
python - "$O/data.jsonl" <<P
import glob, json, os, sys
qs = [json.loads(l)["question"] for l in open(sys.argv[1]) if l.strip()]
home = os.path.expanduser("~/.promptflow/.runs/oracle_run_$$")
fs = glob.glob(home + "/**/outputs.jsonl", recursive=True) or glob.glob(home + "/**/flow_outputs/output.jsonl", recursive=True)
assert fs, "no outputs file under " + home
rows = [json.loads(l) for l in open(fs[0]) if l.strip()]
assert len(rows) == len(qs), (len(rows), rows)
llm = "Prompt flow is a suite of development tools designed to streamline the end-to-end development cycle of LLM-based AI applications."
echoed = 0
for i, r in enumerate(rows):
    q = qs[r.get("line_number", i)]
    a = r["answer"]
    # content_safety_check picks True/False at random; the two branches are llm_result.py and
    # default_result.py, the latter echoing the row's own question.
    assert a == llm or a == f"I'm not familiar with your query: {q}.", (q, r)
    echoed += a != llm
print("rows ok", len(rows), "echoed", echoed)
P
echo "ORACLE PASS"
