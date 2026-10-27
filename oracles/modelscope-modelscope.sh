set -e
source /work/env.sh
cd /work/modelscope
OUT=$(mktemp -d /tmp/oracle_out.XXXX)
cat > $OUT/t.py <<'PY'
import sys, json
from modelscope.pipelines import pipeline
p = pipeline('word-segmentation', model='damo/nlp_structbert_word-segmentation_chinese-base')
r = p('今天天气不错，适合出去游玩')
print(r)
out = r['output']
if isinstance(out, list): out = ' '.join(out)
toks = out.split()
assert len(toks) >= 4, toks
assert '天气' in toks and '游玩' in toks, toks
assert ''.join(toks) == '今天天气不错，适合出去游玩', toks
json.dump({'output': out}, open(sys.argv[1], 'w'), ensure_ascii=False)
PY
timeout 3000 python $OUT/t.py $OUT/result.json
test -s $OUT/result.json
echo "ORACLE PASS"
