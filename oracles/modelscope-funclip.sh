set -e
source /work/env.sh
cd /work/FunClip
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
mkdir -p "$OUT/in" "$OUT/output"
VID="$OUT/in/demo.mp4"
# README.md:161-163 downloads this exact URL (with wget). wget is not in the base image, so fetch it with curl,
# falling back to python urllib; the URL is the README's.
URL="https://huggingface.co/spaces/R1ckShi/FunClip/resolve/main/examples/2022%E4%BA%91%E6%A0%96%E5%A4%A7%E4%BC%9A_%E7%89%87%E6%AE%B5.mp4"
timeout 600 curl -sSfL --retry 3 "$URL" -o "$VID" || timeout 600 python -c "import sys,urllib.request; urllib.request.urlretrieve(sys.argv[1], sys.argv[2])" "$URL" "$VID"
[ "$(stat -c %s "$VID")" -gt 1000000 ]

# Stage 1 (README.md:165-168): recognize; writes <output_dir>/total.srt (funclip/videoclipper.py:520-523)
timeout 2400 python funclip/videoclipper.py --stage 1 --file "$VID" --output_dir "$OUT/output"
test -s "$OUT/output/total.srt"

# Pick a destination sentence from the stage-1 transcript, which is the documented workflow
# ("copy the text segment from below and use stage 2", videoclipper.py:524). The README's literal --dest_text
# is not spoken in the README's example video, so the oracle derives its own from the recognition result.
python - "$OUT/output/total.srt" "$OUT/dest.txt" <<'PY'
import sys, re
t = open(sys.argv[1], encoding='utf-8').read()
assert len(re.findall(r'[一-鿿]', t)) >= 50, "too little Chinese text in total.srt"
assert '-->' in t
lines = [l.strip() for l in t.splitlines()]
# subtitle text lines: pure CJK + CJK punctuation, >= 8 CJK chars (so the clip is a few seconds long)
cand = [l for l in lines if re.fullmatch(r'[一-鿿，。、？！：；]+', l) and len(re.findall(r'[一-鿿]', l)) >= 8]
assert len(cand) >= 2, ("no usable sentence in transcript", lines[:40])
dest = cand[len(cand) // 2]
open(sys.argv[2], 'w', encoding='utf-8').write(dest)
print("dest_text:", dest)
PY
DEST=$(cat "$OUT/dest.txt")

# Stage 2 (README.md:171-177)
timeout 1200 python funclip/videoclipper.py --stage 2 --file "$VID" --output_dir "$OUT/output" \
  --dest_text "$DEST" --start_ost 0 --end_ost 100 --output_file "$OUT/output/res.mp4"
# videoclipper.py:392 appends _no{N} to the requested name when --output_dir is set; accept either name.
CLIP=$(ls "$OUT/output"/res.mp4 "$OUT/output"/res_no*.mp4 2>/dev/null | grep -v tempaudio | head -1)
test -n "$CLIP"
test "$(stat -c %s "$CLIP")" -gt 10000
test -s "$OUT/output/res.srt"   # clip_srt_file = output_file[:-3]+'srt' (videoclipper.py:551)
python - "$CLIP" "$OUT/output/res.srt" "$VID" <<'PY'
import sys, re
from moviepy.editor import VideoFileClip   # moviepy==1.0.3 pinned in requirements.txt
c = VideoFileClip(sys.argv[1]); d = c.duration
full = VideoFileClip(sys.argv[3]).duration
print("clip duration", d, "full", full)
assert 0.5 < d < 60 and d < full, "unexpected clip duration"
assert c.size[0] > 0
s = open(sys.argv[2], encoding='utf-8').read()
assert re.search(r'[一-鿿]', s) and '-->' in s, s
PY
echo "ORACLE PASS"
