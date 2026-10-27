set -e
source /work/env.sh
cd /work/ParlAI
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 1800 parlai display_data -t squad -n 5 --datapath "$OUT/data" > "$OUT/squad.txt" 2>&1 || { tail -30 "$OUT/squad.txt"; exit 1; }
cat "$OUT/squad.txt" | tail -40
grep -q "text:" "$OUT/squad.txt"
grep -q "labels:" "$OUT/squad.txt"
[ "$(grep -c 'text:' "$OUT/squad.txt")" -ge 5 ]
ls "$OUT/data/SQuAD"/*.json >/dev/null
timeout 1800 parlai eval_model -m repeat_label -t integration_tests -dt valid -ne 10 > "$OUT/eval.txt" 2>&1 || { tail -30 "$OUT/eval.txt"; exit 1; }
grep -q "exs" "$OUT/eval.txt"
echo ORACLE PASS
