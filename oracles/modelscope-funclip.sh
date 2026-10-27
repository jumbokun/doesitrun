set -e
source /work/env.sh
cd /work/FunClip
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
mkdir -p "$OUT/in" "$OUT/output"
VID="$OUT/in/demo.mp4"
timeout 600 wget -q "https://huggingface.co/spaces/R1ckShi/FunClip/resolve/main/examples/2022%E4%BA%91%E6%A0%96%E5%A4%A7%E4%BC%9A_%E7%89%87%E6%AE%B5.mp4" -O "$VID"
[ "$(stat -c %s "$VID")" -gt 1000000 ]
timeout 5400 python funclip/videoclipper.py --stage 1 --file "$VID" --output_dir "$OUT/output"
test -s "$OUT/output/total.srt"
python - "$OUT/output/total.srt" <<'PY'
import sys,re
t=open(sys.argv[1],encoding='utf-8').read()
assert len(re.findall(r'[一-鿿]',t))>=50, "too little Chinese text in total.srt"
assert '-->' in t
PY
timeout 1800 python funclip/videoclipper.py --stage 2 --file "$VID" --output_dir "$OUT/output" \
  --dest_text '我们把它跟乡村振兴去结合起来，利用我们的设计的能力' --start_ost 0 --end_ost 100 \
  --output_file "$OUT/output/res.mp4"
test "$(stat -c %s "$OUT/output/res.mp4")" -gt 10000
test -s "$OUT/output/res.srt"
python - "$OUT/output/res.mp4" "$OUT/output/res.srt" "$VID" <<'PY'
import sys,re
from moviepy.editor import VideoFileClip
c=VideoFileClip(sys.argv[1]); d=c.duration
full=VideoFileClip(sys.argv[3]).duration
print("clip duration",d,"full",full)
assert 1<d<60 and d<full, "unexpected clip duration"
assert c.size[0]>0
s=open(sys.argv[2],encoding='utf-8').read()
assert re.search(r'[一-鿿]',s) and '-->' in s
PY
echo "ORACLE PASS"
