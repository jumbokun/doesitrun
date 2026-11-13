set -e
source /work/env.sh
cd /work/gemma
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'P'
import sys
from gemma import gm
model = gm.nn.Gemma3_270M()
params = gm.ckpts.load_params(gm.ckpts.CheckpointPath.GEMMA3_270M_IT)
s = gm.text.ChatSampler(model=model, params=params, multi_turn=True, tokenizer=gm.text.Gemma3Tokenizer())
a = s.chat('What is the capital of France? Answer in one sentence.', max_new_tokens=64) if 'max_new_tokens' in s.chat.__code__.co_varnames else s.chat('What is the capital of France? Answer in one sentence.')
print('ANS1:', repr(a))
b = s.chat('And what is the capital of Germany?')
print('ANS2:', repr(b))
open(sys.argv[1], 'w').write(a + '\n---\n' + b)
assert isinstance(a, str) and len(a.strip()) > 3
assert 'paris' in a.lower(), 'expected Paris'
assert isinstance(b, str) and len(b.strip()) > 3
P
timeout 3000 python $OUT/t.py $OUT/out.txt
test -s $OUT/out.txt
echo "ORACLE PASS"
