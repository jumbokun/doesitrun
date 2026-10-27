set -e
source /work/env.sh
cd /work/PaddleNLP
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'P'
import paddle
from paddlenlp.transformers import AutoTokenizer, AutoModelForCausalLM
tok = AutoTokenizer.from_pretrained("Qwen/Qwen2-0.5B")
model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2-0.5B", dtype="float32")
f = tok("你好！请自我介绍一下。", return_tensors="pd")
out = model.generate(**f, max_length=64)
txt = tok.batch_decode(out[0], skip_special_tokens=True)
print("RESULT:", txt)
open(__import__("sys").argv[1], "w").write(txt[0])
P
timeout 3000 python $OUT/t.py $OUT/out.txt
test -s $OUT/out.txt
[ "$(wc -c < $OUT/out.txt)" -ge 10 ] || { echo short; exit 1; }
echo ORACLE PASS
