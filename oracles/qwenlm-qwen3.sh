set -e
source /work/env.sh
cd /work/Qwen3
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
# README.md:90-130 Transformers snippet, model swapped to the README-listed 0.6B size (README.md:55),
# device_map "cpu" instead of "auto" (no GPU), greedy decoding so the check is reproducible.
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
# v1 grepped "language model|model|text|AI" case-insensitively; "ai" matches almost any English
# text ("explain", "contain"), so it did not check content. An answer to this prompt names the
# topic; observed greedy output: "A large language model (LLM) is a type of artificial intelligence ..."
grep -qi "language model" $OUT/out.txt
python - $OUT/out.txt <<'P'
import sys, re
t = open(sys.argv[1]).read()
words = re.findall(r"[A-Za-z]+", t)
assert len(words) >= 20, words
# degenerate generations (one token repeated) fail this
assert len(set(w.lower() for w in words)) >= 12, words
P
echo "ORACLE PASS"
