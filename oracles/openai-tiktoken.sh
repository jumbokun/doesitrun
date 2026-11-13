set -e
source /work/env.sh
cd /work/tiktoken
export TIKTOKEN_CACHE_DIR=/tmp/oracle_tk_cache_$$
mkdir -p /tmp/oracle_out_$$
timeout 900 python - <<'P'
import tiktoken
enc = tiktoken.get_encoding("o200k_base")
assert enc.decode(enc.encode("hello world")) == "hello world"
assert enc.encode("hello world") == [24912, 2375], enc.encode("hello world")
e2 = tiktoken.encoding_for_model("gpt-4o")
assert e2.name == "o200k_base"
c = tiktoken.get_encoding("cl100k_base")
assert c.encode("hello world") == [15339, 1917], c.encode("hello world")
t = "Tokenization café 日本語 🙂 " * 20
assert c.decode(c.encode(t)) == t and enc.decode(enc.encode(t)) == t
assert len(c.encode(t)) < len(t.encode())
print("ok")
P
echo ORACLE PASS
