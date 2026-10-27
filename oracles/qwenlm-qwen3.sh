set -e
source /work/env.sh
cd /work/Qwen3
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'P'
import sys
from transformers import AutoModelForCausalLM, AutoTokenizer
name = "Qwen/Qwen3-0.6B"
tok = AutoTokenizer.from_pretrained(name)
model = AutoModelForCausalLM.from_pretrained(name, torch_dtype="auto", device_map="cpu")
msgs = [{"role": "user", "content": "Give me a short introduction to large language model."}]
text = tok.apply_chat_template(msgs, tokenize=False, add_generation_prompt=True, enable_thinking=False)
inp = tok([text], return_tensors="pt").to(model.device)
ids = model.generate(**inp, max_new_tokens=100, do_sample=False)
out = tok.decode(ids[0][len(inp.input_ids[0]):], skip_special_tokens=True)
open(sys.argv[1], "w").write(out)
print(out)
P
timeout 3000 python $OUT/t.py $OUT/out.txt
test $(wc -c < $OUT/out.txt) -gt 100
grep -qi -E "language model|model|text|AI" $OUT/out.txt
echo "ORACLE PASS"
