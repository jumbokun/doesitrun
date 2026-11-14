set -e
source /work/env.sh
cd /work/gpt-oss
timeout 1500 bash /work/run.sh
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
# README.md:176-188 (Ollama section): `ollama pull gpt-oss:20b` / `ollama run gpt-oss:20b`.
# Ollama serves an OpenAI-compatible /v1/chat/completions on 127.0.0.1:11434 by default.
curl -s -m 1800 -o $OUT/resp.json -w '%{http_code}' http://127.0.0.1:11434/v1/chat/completions \
 -H 'Content-Type: application/json' \
 -d '{"model":"gpt-oss:20b","messages":[{"role":"user","content":"What is 2+2? Reply with just the number."}],"max_tokens":400,"temperature":0,"stream":false}' > $OUT/code
[ "$(cat $OUT/code)" = "200" ] || { echo "bad http $(cat $OUT/code)"; cat $OUT/resp.json; exit 1; }
python3 -I - $OUT/resp.json <<'P'
import json, re, sys
r = json.load(open(sys.argv[1]))
m = r["choices"][0]["message"]
content = m.get("content") or ""
reasoning = (m.get("reasoning") or "") + (m.get("reasoning_content") or "")
print("content:", content); print("reasoning:", reasoning[:500])
assert r["model"].startswith("gpt-oss"), r["model"]
assert r["usage"]["completion_tokens"] > 0
txt = content + "\n" + reasoning
assert txt.strip(), "empty generation"
# v1 accepted any non-empty text; a model that loads but decodes garbage passed. gpt-oss is a
# reasoning model, so the answer may sit in the content or (if max_tokens cut it) the reasoning.
assert re.search(r"\b4\b|\bfour\b", txt, re.I), "answer 4 not found in generation"
# the text must look like language, not token soup: mostly ASCII letters/digits/space/punct
printable = sum(ch.isascii() and (ch.isalnum() or ch.isspace() or ch in ".,:;!?'\"()+-=*/") for ch in txt)
assert printable / max(1, len(txt)) > 0.8, "generation does not look like text"
P
echo "ORACLE PASS"
