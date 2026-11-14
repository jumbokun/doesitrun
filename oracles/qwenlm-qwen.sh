set -e
source /work/env.sh
cd /work/Qwen
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
# Qwen/Qwen-1_8B-Chat is linked from README.md:27 on both Hugging Face and ModelScope; README.md:225-245
# documents downloading from ModelScope and loading from a local directory. An install that does that
# exports QWEN_CKPT=<dir> in /work/env.sh; otherwise the hub id is used (-c = --checkpoint-path, cli_demo.py).
CKPT="${QWEN_CKPT:-Qwen/Qwen-1_8B-Chat}"
echo "checkpoint: $CKPT"
printf 'What is the capital of France? Answer briefly.\n:q\n' > $OUT/in.txt
# --cpu-only -> device_map="cpu" (cli_demo.py:49-52); ':q' exits (cli_demo.py:32,135)
timeout 3000 python cli_demo.py -c "$CKPT" --cpu-only < $OUT/in.txt > $OUT/out.txt 2>&1 || { tail -50 $OUT/out.txt; exit 1; }
tail -30 $OUT/out.txt
# The demo prints "\nQwen-Chat: {response}" for each streamed chunk (cli_demo.py:199-201); check the
# last (complete) response, not the whole log, so an error message cannot satisfy the check.
python - "$OUT/out.txt" <<'P'
import sys
t = open(sys.argv[1], encoding='utf-8', errors='replace').read()
i = t.rfind('Qwen-Chat:')
assert i >= 0, 'no Qwen-Chat response printed'
resp = t[i + len('Qwen-Chat:'):].split('User>')[0]
print('RESPONSE:', resp.strip()[:200])
assert 'paris' in resp.lower(), 'response does not mention Paris'
P
echo "ORACLE PASS"
