set -e
source /work/env.sh
cd /work/garak
O=$(mktemp -d /tmp/garak_out.XXXXXX)

# 1. README "Getting started": garak --list_probes. Plugin lines are "probes: <name>" with ANSI colour codes
#    between the prefix and the name (garak/command.py:233-239), so strip escapes before matching.
timeout 300 python -m garak --list_probes > $O/probes.txt 2>&1
sed -e 's/\x1b\[[0-9;]*m//g' $O/probes.txt > $O/probes.clean
grep -Eq "^probes: dan\.Dan_11_0" $O/probes.clean
grep -Eq "^probes: encoding" $O/probes.clean
grep -Eq "^probes: test\.Test" $O/probes.clean

# 2. Test generator (README "Intro to generators / Test": test.Repeat repeats the prompt back) with the
#    test.Test probe and always.Pass detector (README.md:297-299 pattern).
timeout 600 python -m garak -t test.Repeat -p test.Test -d always.Pass --report_prefix $O/rep > $O/rep.log 2>&1 || { tail -30 $O/rep.log; exit 1; }

# 3. README "Examples": Hugging Face GPT-2 against DAN 11.0 (CPU-feasible, ungated gpt2).
timeout 1200 python3 -m garak --target_type huggingface --target_name gpt2 --spec probes.dan.Dan_11_0 \
  --report_prefix $O/dan > $O/dan.log 2>&1 || { tail -40 $O/dan.log; exit 1; }

# 4. Same local HF generator on the short test.Test prompts, so real gpt2 generations can be checked
#    (the DAN 11.0 prompt is ~4.7k chars, close to gpt2's 1024-token context, so its outputs are not asserted).
timeout 1200 python3 -m garak --target_type huggingface --target_name gpt2 -p test.Test \
  -d always.Pass --generations 1 --report_prefix $O/hf > $O/hf.log 2>&1 || { tail -40 $O/hf.log; exit 1; }

python3 -I - "$O" <<'PY'
import json, sys
o = sys.argv[1]
def load(name):
    rows = [json.loads(l) for l in open(f"{o}/{name}.report.jsonl", encoding="utf-8") if l.strip()]
    assert rows, name
    return rows
def attempts(rows, probe):
    return [r for r in rows if r.get("entry_type") == "attempt" and r.get("probe_classname") == probe]
def evals(rows, probe_sub, det):
    return [r for r in rows if r.get("entry_type") == "eval" and probe_sub in str(r.get("probe"))
            and str(r.get("detector", "")).endswith(det)]
def out_texts(a):
    return [x.get("text") for x in a.get("outputs") or [] if isinstance(x, dict)]

# --- test.Repeat: every output echoes the last prompt turn (garak/generators/test.py:34-37)
rep = load("rep")
ra = attempts(rep, "test.Test")
assert len(ra) >= 8, len(ra)  # test.Test has 8 prompts (garak/probes/test.py)
echo = 0
for a in ra:
    texts = out_texts(a)
    turns = (a.get("prompt") or {}).get("turns") or []
    last = turns[-1]["content"]["text"] if turns else None
    if texts and last is not None and all(t == last for t in texts):
        echo += 1
assert echo >= 7, ("Repeat did not echo prompts", echo, len(ra))  # 8 prompts; tolerate the empty one
assert any("The quick brown fox" in json.dumps(a, ensure_ascii=False) for a in ra)
e = evals(rep, "test.Test", "always.Pass")
assert e and all(x["passed"] == x["total_evaluated"] and x["total_evaluated"] > 0 for x in e), e

# --- README example: huggingface gpt2 x dan.Dan_11_0
dan = load("dan")
setup = [r for r in dan if r.get("entry_type") == "start_run setup"]
assert setup and setup[0].get("plugins.target_type") == "huggingface" and setup[0].get("plugins.target_name") == "gpt2", setup[:1]
da = attempts(dan, "dan.Dan_11_0")
assert da, "no DAN attempts"
assert any("DAN" in json.dumps(a.get("prompt"), ensure_ascii=False) for a in da)
assert evals(dan, "Dan_11_0", "dan.DAN"), "no dan.DAN eval entry"  # primary_detector, garak/probes/dan.py:54

# --- huggingface gpt2 x test.Test: real local generations exist
hf = load("hf")
ha = attempts(hf, "test.Test")
assert len(ha) >= 8, len(ha)
nonempty = [t for a in ha for t in out_texts(a) if isinstance(t, str) and t.strip()]
print("repeat attempts", len(ra), "dan attempts", len(da), "gpt2 non-empty outputs", len(nonempty))
assert len(nonempty) >= 3, nonempty
PY
echo ORACLE PASS
