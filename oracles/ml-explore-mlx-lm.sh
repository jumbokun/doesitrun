set -e
source /work/env.sh
cd /work/mlx-lm
O=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 3000 mlx_lm.generate --prompt "How tall is Mt Everest?" --max-tokens 64 > $O/cli.txt 2>&1
cat $O/cli.txt
grep -qi "everest\|8,8\|8848\|29,03\|29,0\|meters\|feet" $O/cli.txt
grep -q "Generation:" $O/cli.txt
cat > $O/api.py <<'P'
from mlx_lm import load, generate
m, t = load("mlx-community/Llama-3.2-3B-Instruct-4bit")
p = t.apply_chat_template([{"role":"user","content":"How tall is Mt Everest?"}], add_generation_prompt=True)
out = generate(m, t, prompt=p, max_tokens=64)
print("OUT:", out)
assert len(out.strip()) > 20
import re
assert re.search(r"8,?8\d\d|29,?0\d\d|meter|feet|Everest", out, re.I)
P
timeout 1500 python $O/api.py
echo "ORACLE PASS"
