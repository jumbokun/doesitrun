set -e
source /work/env.sh
cd /work/ClearerVoice-Studio
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
cd clearvoice
timeout 3000 python - "$OUT" <<'PY'
import sys, wave, os
from clearvoice import ClearVoice
out = sys.argv[1]
cv = ClearVoice(task='speech_enhancement', model_names=['FRCRN_SE_16K'])
res = cv(input_path='samples/input.wav', online_write=False)
dst = os.path.join(out, 'enh.wav')
cv.write(res, output_path=dst)
assert os.path.exists(dst), 'no output'
w = wave.open(dst)
n, sr = w.getnframes(), w.getframerate()
print('out', n, sr, os.path.getsize(dst))
assert sr == 16000 and 30000 < n < 50000, 'unexpected shape'
import numpy as np
d = np.frombuffer(w.readframes(n), dtype=np.int16).astype(float)
assert np.abs(d).max() > 0 and np.isfinite(d).all(), 'silent output'
PY
echo ORACLE PASS
