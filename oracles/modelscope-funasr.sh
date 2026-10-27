set -e
source /work/env.sh
cd /work/FunASR
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'P'
import sys, re
from funasr import AutoModel
from funasr.utils.postprocess_utils import rich_transcription_postprocess
m = AutoModel(model="iic/SenseVoiceSmall", vad_model="fsmn-vad", spk_model="cam++", device="cpu", disable_update=True)
r = m.generate(input="/work/FunASR/runtime/funasr_api/asr_example.wav", batch_size_s=300)
segs = r[0]["sentence_info"]
assert len(segs) >= 1, "no segments"
txt = ""
for s in segs:
    assert "spk" in s and "start" in s
    t = rich_transcription_postprocess(s["sentence"])
    print(f"[{s['start']/1000:.1f}s] Speaker {s['spk']}: {t}")
    txt += t
assert len(re.findall(r'[一-鿿]', txt)) >= 5, "no Chinese text: " + txt
open(sys.argv[1], "w").write(txt)
P
timeout 3000 python $OUT/t.py $OUT/out.txt
test -s $OUT/out.txt
echo "ORACLE PASS"
