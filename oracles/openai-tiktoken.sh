set -e
source /work/env.sh
test -d /work/tiktoken
# v1 did `cd /work/tiktoken`: the source tree's tiktoken/ package has no compiled _tiktoken
# extension (setup.py builds it as tiktoken._tiktoken), so it shadowed the installed package and
# `import tiktoken` failed for a correct install. Run from a fresh directory instead.
W=$(mktemp -d /tmp/oracle.XXXXXX)
cd "$W"
export TIKTOKEN_CACHE_DIR="$W/cache"
timeout 900 python - <<'P'
import tiktoken
# (an editable install that builds _tiktoken in place is also fine; cwd is no longer the source tree)

# README quickstart (README.md:6-13)
enc = tiktoken.get_encoding("o200k_base")
assert enc.decode(enc.encode("hello world")) == "hello world"
assert enc.encode("hello world") == [24912, 2375], enc.encode("hello world")
assert tiktoken.encoding_for_model("gpt-4o").name == "o200k_base"   # tiktoken/model.py:37
assert tiktoken.encoding_for_model("gpt-4").name == "cl100k_base"   # tiktoken/model.py:38

# exact ids from the repo's own tests (tests/test_encoding.py:15-22)
g = tiktoken.get_encoding("gpt2")
assert g.encode("hello world") == [31373, 995], g.encode("hello world")
c = tiktoken.get_encoding("cl100k_base")
assert c.encode("hello world") == [15339, 1917], c.encode("hello world")
assert c.encode("hello <|endoftext|>", allowed_special="all") == [15339, 220, 100257]
# special tokens are disallowed by default (tiktoken/core.py encode raises ValueError)
try:
    c.encode("hello <|endoftext|>")
    raise AssertionError("special token was not rejected")
except ValueError:
    pass

# round trips on non-ASCII text, and batch encoding
t = "Tokenization café 日本語 🙂 " * 20
for e in (enc, c, g):
    assert e.decode(e.encode(t)) == t
assert len(c.encode(t)) < len(t.encode())
batch = c.encode_batch(["hello world", "goodbye world"])
assert batch[0] == [15339, 1917] and len(batch) == 2 and c.decode(batch[1]) == "goodbye world"
print("ok")
P
echo "ORACLE PASS"
