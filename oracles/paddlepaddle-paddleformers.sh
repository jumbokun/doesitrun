set -e
source /work/env.sh
cd /work/PaddleFormers
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'P'
import sys
from paddleformers.transformers import AutoTokenizer, AutoModelForCausalLM
tok = AutoTokenizer.from_pretrained("Qwen/Qwen3-0.6B-Base")
ids = tok.encode("中华人民共和国")
ids = ids["input_ids"] if isinstance(ids, dict) else ids
if hasattr(ids, "tolist"): ids = ids.tolist()
print("IDS", ids)
assert list(ids) == [105492, 104773], ids
model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen3-0.6B-Base", dtype="bfloat16").eval()
prompt = "请给我一段大模型的简短介绍："
feat = tok(prompt, return_tensors="pd")
out = model.generate(**feat, max_new_tokens=32)
oid = out[0].tolist()[0]
text = tok.decode(oid, skip_special_tokens=True)
print("TEXT", text)
open(sys.argv[1], "w").write(text)
assert len(oid) > 5
P
timeout 3000 python $OUT/t.py $OUT/out.txt 2>&1 | tee $OUT/log.txt
test -s $OUT/out.txt
python - $OUT/out.txt <<'P'
import sys
t = open(sys.argv[1]).read()
assert len(t.strip()) > len("请给我一段大模型的简短介绍：") + 3, t
P
echo "ORACLE PASS"
