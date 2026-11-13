set -e
source /work/env.sh
cd /work/whisper
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 1800 whisper tests/jfk.flac --model tiny.en --device cpu --fp16 False --output_dir "$OUT" --output_format all
test -s "$OUT/jfk.txt"
test -s "$OUT/jfk.srt"
test -s "$OUT/jfk.json"
python - "$OUT/jfk.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
t=d["text"].lower()
assert "ask not what your country can do for you" in t, t
assert len(d["segments"])>=1
print(t)
PY
echo "ORACLE PASS"
