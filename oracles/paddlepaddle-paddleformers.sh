set -e
set -o pipefail
source /work/env.sh
cd /work/PaddleFormers
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'P'
import sys
from paddleformers.transformers import AutoTokenizer, AutoModelForCausalLM
# README.md:288-297 tokenizer snippet and its documented ids
tok = AutoTokenizer.from_pretrained("Qwen/Qwen3-0.6B-Base")
ids = tok.encode("中华人民共和国")
ids = ids["input_ids"] if isinstance(ids, dict) else ids
if hasattr(ids, "tolist"): ids = ids.tolist()
print("IDS", ids)
assert list(ids) == [105492, 104773], ids
# README.md:301-311 generation snippet (max_new_tokens reduced from 256 to keep CPU time short)
model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen3-0.6B-Base", dtype="bfloat16").eval()
prompt = "请给我一段大模型的简短介绍："
feat = tok(prompt, return_tensors="pd")
out = model.generate(**feat, max_new_tokens=32)
oid = out[0].tolist()[0]
text = tok.decode(oid, skip_special_tokens=True)
print("TEXT", text)
open(sys.argv[1], "w").write(text)
assert len(oid) > 5
# v2: the README snippet's output cannot be pinned, so also check that generation is actually correct, not just
# non-empty, with a greedy completion any working Qwen3-0.6B-Base gives.
# decode_strategy is a documented generate() kwarg (paddleformers/generation/utils.py:900).
feat2 = tok("中华人民共和国的首都是", return_tensors="pd")
out2 = model.generate(**feat2, max_new_tokens=8, decode_strategy="greedy_search")
t2 = tok.decode(out2[0].tolist()[0], skip_special_tokens=True)
print("CAPITAL", t2)
assert "北京" in t2, t2
P
timeout 3000 python $OUT/t.py $OUT/out.txt 2>&1 | tee $OUT/log.txt
test -s $OUT/out.txt
python - $OUT/out.txt <<'P'
import sys
t = open(sys.argv[1]).read().strip()
assert len(t) > len("请给我一段大模型的简短介绍：") + 3, t
# a working model continues a Chinese prompt in Chinese; garbage/one repeated token fails this
cjk = [c for c in t if "一" <= c <= "鿿"]
assert len(cjk) >= 8 and len(set(cjk)) >= 5, t
P
echo "ORACLE PASS"
