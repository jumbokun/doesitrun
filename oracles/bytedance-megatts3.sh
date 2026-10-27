set -e
source /work/env.sh
cd /work/MegaTTS3
export PYTHONPATH="/work/MegaTTS3:$PYTHONPATH"
export CUDA_VISIBLE_DEVICES=""
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
timeout 5400 python tts/infer_cli.py --input_wav assets/English_prompt.wav \
  --input_text "Hello world, this is a short test of speech synthesis." \
  --output_dir "$OUT" --time_step 16 --p_w 2.0 --t_w 3.0
python - "$OUT" <<'PY'
import sys, glob, wave
fs = glob.glob(sys.argv[1] + "/*.wav")
assert fs, "no wav produced"
w = wave.open(fs[0])
dur = w.getnframes() / w.getframerate()
print("file", fs[0], "rate", w.getframerate(), "dur", dur)
assert w.getframerate() >= 16000 and 1.5 < dur < 30, "implausible audio"
import os
assert os.path.getsize(fs[0]) > 50000
import numpy as np
d = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16 if w.getsampwidth()==2 else np.uint8)
assert d.std() > 0 and np.abs(d).max() > 0, "silent audio"
PY
echo ORACLE PASS
