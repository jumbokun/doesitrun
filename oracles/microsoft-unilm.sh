set -e
source /work/env.sh
cd /work/unilm
cd e5
OUT=$(mktemp -d /tmp/e5out.XXXXXX)
timeout 3000 python -u mteb_except_retrieval_eval.py --model-name-or-path intfloat/e5-small-v2 --task-types STS --dry-run --output-dir "$OUT"
python - "$OUT" <<'P'
import json,glob,sys
fs=glob.glob(sys.argv[1]+'/**/STS12.json',recursive=True)
assert fs,'no STS12.json'
d=json.load(open(fs[0]))
s=d['test']['cos_sim']['spearman']
print('STS12 spearman',s)
assert 0.6<s<0.9,s
P
echo "ORACLE PASS"
