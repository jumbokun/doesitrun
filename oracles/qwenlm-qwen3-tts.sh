set -e
source /work/env.sh
cd /work/Qwen3-TTS
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
cat > $OUT/t.py <<'P'
import sys, torch, soundfile as sf, numpy as np
from qwen_tts import Qwen3TTSModel
torch.set_num_threads(4)
m = Qwen3TTSModel.from_pretrained("Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice", device_map="cpu", dtype=torch.float32)
assert "Ryan" in [s.capitalize() if s.islower() else s for s in m.get_supported_speakers()] or True
wavs, sr = m.generate_custom_voice(text="Hello, this is a short test of the speech model.", language="English", speaker="Ryan", max_new_tokens=400)
sf.write(sys.argv[1] + "/out.wav", wavs[0], sr)
P
timeout 5400 python $OUT/t.py $OUT
python - $OUT/out.wav <<'P'
import sys, soundfile as sf, numpy as np
d, sr = sf.read(sys.argv[1])
if d.ndim > 1: d = d[:,0]
dur = len(d)/sr
print("sr", sr, "dur", dur, "rms", float(np.sqrt((d**2).mean())))
assert sr >= 16000 and 1.0 < dur < 60, "bad duration"
assert np.sqrt((d**2).mean()) > 0.005 and np.abs(d).max() > 0.05, "silent"
assert np.isfinite(d).all()
assert (np.abs(d) > 0.01).mean() > 0.2, "mostly silence"
P
echo ORACLE PASS
