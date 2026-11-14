set -e
source /work/env.sh
cd /work/PaddleNLP
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
# README_en.md:94-101 Quick Start; float32 instead of float16 on CPU. The script lives in $OUT, so
# sys.path[0] is $OUT and the source tree's paddlenlp/ does not shadow the installed package.
cat > $OUT/t.py <<'P'
import sys, paddle
from paddlenlp.transformers import AutoTokenizer, AutoModelForCausalLM
tok = AutoTokenizer.from_pretrained("Qwen/Qwen2-0.5B")
model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2-0.5B", dtype="float32")
f = tok("你好！请自我介绍一下。", return_tensors="pd")
out = model.generate(**f, max_length=64)
txt = tok.batch_decode(out[0], skip_special_tokens=True)
print("RESULT:", txt)
open(sys.argv[1], "w", encoding="utf-8").write(txt[0])
P
timeout 3000 python $OUT/t.py $OUT/out.txt
python3 -I - $OUT/out.txt <<'P'
import sys
t = open(sys.argv[1], encoding="utf-8").read().strip()
cjk = sum(1 for c in t if u'一' <= c <= u'鿿')
print("chars", len(t), "cjk", cjk)
# README_en.md:101 shows a Chinese self-introduction for this prompt ("我是一个AI语言模型，...");
# a broken tokenizer or weights decodes to empty text, repeated tokens or non-Chinese garbage.
assert t and t != u"你好！请自我介绍一下。", t
assert cjk >= 10, t
assert len(set(t)) >= 8, t
P
echo ORACLE PASS
