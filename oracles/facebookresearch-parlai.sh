set -e
source /work/env.sh
cd /work/ParlAI
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
strip() { sed 's/\x1b\[[0-9;]*m//g' "$1"; }   # colorize() is a no-op off-tty (parlai/utils/strings.py:76-85); strip anyway

# README "Examples" #1: parlai display_data -t squad (README.md:132-134), 5 examples into a fresh datapath.
timeout 1800 parlai display_data -t squad -n 5 --datapath "$OUT/data" > "$OUT/squad.txt" 2>&1 || { tail -40 "$OUT/squad.txt"; exit 1; }
strip "$OUT/squad.txt" > "$OUT/squad.clean"
tail -30 "$OUT/squad.clean"
# simple_display (parlai/scripts/display_data.py) prints, per example: an episode header on turn 0,
# the text (context + question), then the label indented by 3 spaces. There is no "text:"/"labels:" prefix.
[ "$(grep -c '^- - - NEW EPISODE: squad - - -$' "$OUT/squad.clean")" -ge 1 ]
[ "$(grep -c '^   [^ ]' "$OUT/squad.clean")" -ge 5 ]
if grep -q '\[no labels field\]\|\[no text field\]' "$OUT/squad.clean"; then echo "examples missing text/labels"; exit 1; fi
# Training data is iterated in order (display_data forces train:ordered); SQuAD v1.1 train's first
# question is the Lourdes one, answer "Saint Bernadette Soubirous".
grep -q '^To whom did the Virgin Mary allegedly appear in 1858 in Lourdes France?$' "$OUT/squad.clean"
grep -q '^   Saint Bernadette Soubirous$' "$OUT/squad.clean"
# parlai/tasks/squad/build.py downloads train-v1.1.json and dev-v1.1.json
[ "$(stat -c %s "$OUT/data/SQuAD/train-v1.1.json")" -gt 10000000 ]
test -s "$OUT/data/SQuAD/dev-v1.1.json"

# README "Examples" #2: parlai eval_model -m ir_baseline -t personachat -dt valid (README.md:136-139),
# capped at 200 examples with the documented -ne/--num-examples flag (parlai/scripts/eval_model.py:94);
# --report-filename writes the report as JSON (eval_model.py:56,121-140).
timeout 2400 parlai eval_model -m ir_baseline -t personachat -dt valid -ne 200 \
  --datapath "$OUT/data" --report-filename "$OUT/report.json" > "$OUT/eval.txt" 2>&1 || { tail -40 "$OUT/eval.txt"; exit 1; }
tail -15 "$OUT/eval.txt"
python - "$OUT/report.json" <<'P'
import json, sys
r = json.load(open(sys.argv[1]))["report"]
print({k: r[k] for k in sorted(r) if not isinstance(r[k], (dict, list))})
assert int(r["exs"]) == 200, r.get("exs")
acc = float(r["accuracy"])
assert 0.0 <= acc <= 1.0, acc
print("eval ok")
P
echo ORACLE PASS
