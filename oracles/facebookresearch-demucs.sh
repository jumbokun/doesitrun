set -e
source /work/env.sh
cd /work/demucs
OUT=$(mktemp -d /tmp/demucs_out.XXXXXX)
# README.md:196-197 `demucs --two-stems=vocals myfile.mp3`, python3 -m form (README.md:189),
# -d cpu (README.md:202); default model htdemucs (README.md:57).
timeout 3000 python3 -m demucs --two-stems=vocals -d cpu -o "$OUT" test.mp3
D="$OUT/htdemucs/test"
for f in vocals no_vocals; do
  test -f "$D/$f.wav" || { echo "missing $f.wav"; exit 1; }
  s=$(stat -c %s "$D/$f.wav"); echo "$f.wav $s"
  [ "$s" -gt 500000 ] || { echo "too small"; exit 1; }
done
# Content check (v1 only checked size/duration/channels, which a model emitting garbage passes):
# README.md:205-209: stems are stereo 44.1 kHz int16 wav; separate.py:208-218 builds no_vocals by
# adding the other stems, so vocals + no_vocals must reconstruct the input mix.
python3 - "$D" test.mp3 <<'P'
import sys, wave
import numpy as np
D, mix_path = sys.argv[1], sys.argv[2]
def read_wav(p):
    try:
        w = wave.open(p)  # stdlib wave rejects WAVE_FORMAT_EXTENSIBLE before Python 3.12
        sr, ch, width = w.getframerate(), w.getnchannels(), w.getsampwidth()
        assert width == 2, (p, "not int16", width)
        x = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float32) / 32768.0
        x = x.reshape(-1, ch).T
    except wave.Error:
        try:
            import soundfile as sf
            x, sr = sf.read(p, dtype="float32", always_2d=True)
            x = x.T
        except ImportError:
            import torchaudio as ta
            t, sr = ta.load(p)
            x = t.numpy()
    assert sr == 44100 and x.shape[0] == 2, (p, sr, x.shape)
    return x
voc, nov = read_wav(f"{D}/vocals.wav"), read_wav(f"{D}/no_vocals.wav")
# load the mix the way demucs does (api.py:210-239: ffmpeg first, torchaudio fallback)
from demucs.audio import AudioFile, convert_audio
try:
    mix = AudioFile(mix_path).read(streams=0, samplerate=44100, channels=2)
except Exception:
    import torchaudio as ta
    wav, sr = ta.load(mix_path)
    mix = convert_audio(wav, sr, 44100, 2)
mix = mix.numpy()
n = min(mix.shape[1], voc.shape[1], nov.shape[1])
print("samples", mix.shape[1], voc.shape[1], nov.shape[1])
assert n > 44100 * 5 and abs(voc.shape[1] - mix.shape[1]) < 44100 // 2, "stem length differs from input"
assert np.isfinite(voc).all() and np.isfinite(nov).all()
rms = lambda x: float(np.sqrt((x ** 2).mean()))
print("rms mix", rms(mix), "vocals", rms(voc), "no_vocals", rms(nov))
assert rms(nov) > 0.01, "no_vocals is silent"
s, m = (voc + nov)[:, :n].ravel(), mix[:, :n].ravel()
corr = float(np.corrcoef(s, m)[0, 1])
print("corr(vocals+no_vocals, mix)", corr)
assert corr > 0.8, corr
P
echo "ORACLE PASS"
