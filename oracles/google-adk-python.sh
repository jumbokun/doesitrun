set -e
source /work/env.sh
cd /work/adk-python
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
# README "Run Locally": `adk run path/to/my_agent "hello"` (single-step mode, src/google/adk/cli/cli_tools_click.py cli_run docstring).
# Agents: README "Samples" -> contributing/samples/ "runnable example agents". These two Workflows are pure
# function nodes (no LLM), so no API key is involved. --in_memory/--jsonl are documented cli_run options.
S=contributing/samples/workflows
test -f $S/fan_out_fan_in/agent.py
test -f $S/state/agent.py
timeout 600 adk run --in_memory --jsonl $S/fan_out_fan_in "Hello World" > $OUT/fan.jsonl 2> $OUT/fan.err || { cat $OUT/fan.err; exit 1; }
timeout 600 adk run --in_memory --jsonl $S/state "hello adk" > $OUT/state.jsonl 2> $OUT/state.err || { cat $OUT/state.err; exit 1; }
cat $OUT/fan.jsonl $OUT/state.jsonl
python3 - "$OUT/fan.jsonl" "$OUT/state.jsonl" <<'PY'
import json, sys
def load(p):
    evs = [json.loads(l) for l in open(p, encoding="utf-8") if l.strip().startswith("{")]
    assert evs, f"no JSONL events in {p}"
    return evs, json.dumps(evs, ensure_ascii=False)
fan, fan_s = load(sys.argv[1])
# fan_out_fan_in/agent.py: make_uppercase / count_characters / reverse_string -> JoinNode -> aggregate message
for frag in ("Uppercase: HELLO WORLD", "Character Count: 11", "Reversed: dlroW olleH"):
    assert frag in fan_s, (frag, fan_s[:2000])
st, st_s = load(sys.argv[2])
# state/agent.py: read_state_via_ctx + read_state_via_param (compare tests/go.json: 'Final Result: GO (Original was: go)!')
assert "Final Result: HELLO ADK (Original was: hello adk)!" in st_s, st_s[:2000]
print("events", len(fan), len(st))
PY
echo ORACLE PASS
