set -e
source /work/env.sh
cd /work/evalscope
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
timeout 5400 evalscope eval --model Qwen/Qwen2.5-0.5B-Instruct --datasets gsm8k --limit 5 --work-dir "$OUT" 2>&1 | tail -n 40
python - "$OUT" <<'P'
import sys,glob,json
out=sys.argv[1]
fs=[f for f in glob.glob(out+'/**/reports/**/*gsm8k*.json',recursive=True)]
assert fs, "no gsm8k report json found"
txt=open(fs[0]).read()
d=json.loads(txt)
assert len(txt)>100
s=json.dumps(d)
assert 'score' in s, "no score in report"
assert '"num": 5' in s or '"num":5' in s or 'gsm8k' in s.lower()
print("report",fs[0])
P
rev=$(find "$OUT" -ipath '*reviews*' -name '*gsm8k*.jsonl' | head -1)
[ -n "$rev" ] && [ "$(wc -l < "$rev")" -ge 5 ]
echo ORACLE PASS
