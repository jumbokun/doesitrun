set -e
source /work/env.sh
cd /work/Qwen3-TTS
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
# README.md:150-170 CustomVoice snippet with the README-listed 0.6B CustomVoice model, on CPU in fp32
# (README uses cuda:0 + bf16 + flash_attention_2, none available here).
cat > $OUT/t.py <<'P'
import sys, torch, soundfile as sf
from qwen_tts import Qwen3TTSModel
torch.set_num_threads(4)
m = Qwen3TTSModel.from_pretrained("Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice", device_map="cpu", dtype=torch.float32)
# qwen3_tts_model.py:842-854 returns a sorted, lowercased speaker list; README.md:196 lists Ryan.
# (v1 had `assert ... or True`, which never fails.)
spk = m.get_supported_speakers()
assert spk and "ryan" in [s.lower() for s in spk], spk
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
# 10-word sentence: runs observed 4.2 s and 6.9 s. 400 codec tokens at 12 Hz is ~33 s, so a model
# that never emits end-of-speech runs into the token cap; < 20 s catches that.
assert sr >= 16000 and 1.0 < dur < 20, "bad duration"
assert np.isfinite(d).all()
assert np.sqrt((d**2).mean()) > 0.005 and np.abs(d).max() > 0.05, "silent"
assert (np.abs(d) > 0.01).mean() > 0.2, "mostly silence"
P
echo ORACLE PASS
