set -e
source /work/env.sh
# Run from a fresh dir so the source tree (/work/mlx-lm/mlx_lm) is not what gets imported by accident.
O=$(mktemp -d /tmp/oracle.XXXXXX)
cd "$O"
# README "Quick Start". Default model: generate.py:59; greedy by default (DEFAULT_TEMP = 0.0, generate.py:51).
# Budgets: CLI 2100 s + API 1200 s stay inside ORACLE_SEC=3600 (the old 3000 + 1500 did not).
timeout 2100 mlx_lm.generate --prompt "How tall is Mt Everest?" --max-tokens 64 > "$O/cli.txt" 2>&1
cat "$O/cli.txt"
# verbose output (default --verbose True, generate.py:180-183) frames the text with "==========" and then
# prints "Generation: N tokens" (generate.py:804-827); the prompt itself is not echoed.
grep -q "Generation:" "$O/cli.txt"
python3 - "$O/cli.txt" <<'P'
import re, sys
s = open(sys.argv[1], encoding="utf-8", errors="replace").read()
parts = s.split("=" * 10)
assert len(parts) >= 3, "no generation block"
text = parts[1].strip()
print("CLI TEXT:", text)
assert len(text) > 20, text
assert re.search(r"8,?8\d\d|29,?0\d\d|meter|metre|feet|Everest", text, re.I), text
P
# README "Python API"
cat > "$O/api.py" <<'P'
import re
from mlx_lm import load, generate
m, t = load("mlx-community/Llama-3.2-3B-Instruct-4bit")
p = t.apply_chat_template([{"role": "user", "content": "How tall is Mt Everest?"}], add_generation_prompt=True)
out = generate(m, t, prompt=p, max_tokens=64)
print("OUT:", out)
assert isinstance(out, str) and len(out.strip()) > 20
assert re.search(r"8,?8\d\d|29,?0\d\d|meter|metre|feet|Everest", out, re.I)
P
timeout 1200 python "$O/api.py"
echo "ORACLE PASS"
