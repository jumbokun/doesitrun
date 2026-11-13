set -e
source /work/env.sh
cd /work/gpt-2
export PYTHONIOENCODING=UTF-8
test -s models/124M/model.ckpt.data-00000-of-00001 || { echo "model 124M missing"; exit 1; }
O=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 1500 python3 src/generate_unconditional_samples.py --nsamples 1 --length 50 --top_k 40 --temperature 0.7 --seed 1 > $O/uncond.txt 2> $O/uncond.err || { tail -20 $O/uncond.err; exit 1; }
grep -q "SAMPLE 1" $O/uncond.txt
body=$(sed '/SAMPLE 1/d;/^=*$/d' $O/uncond.txt | wc -c)
[ "$body" -gt 80 ] || { echo "unconditional sample too short"; exit 1; }
printf 'The capital of France is\n' | timeout 1500 python3 src/interactive_conditional_samples.py --nsamples 1 --length 40 --top_k 40 --seed 1 > $O/cond.txt 2> $O/cond.err || true
grep -q "SAMPLE 1" $O/cond.txt || { tail -20 $O/cond.err; echo "no conditional sample"; exit 1; }
after=$(sed -n '/SAMPLE 1/,$p' $O/cond.txt | sed '1d;/^=*$/d;/Model prompt/d' | wc -c)
[ "$after" -gt 40 ] || { echo "conditional sample too short"; exit 1; }
echo ORACLE PASS
