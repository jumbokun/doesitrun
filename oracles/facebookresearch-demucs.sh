set -e
source /work/env.sh
cd /work/demucs
OUT=$(mktemp -d /tmp/demucs_out.XXXXXX)
timeout 3000 python3 -m demucs --two-stems=vocals -d cpu -o "$OUT" test.mp3
D="$OUT/htdemucs/test"
for f in vocals no_vocals; do
  test -f "$D/$f.wav" || { echo "missing $f.wav"; exit 1; }
  s=$(stat -c %s "$D/$f.wav"); echo "$f.wav $s"
  [ "$s" -gt 500000 ] || { echo "too small"; exit 1; }
done
python3 - "$D" <<'P'
import sys,wave
for f in ("vocals","no_vocals"):
    try:
        w=wave.open(f"{sys.argv[1]}/{f}.wav"); d=w.getnframes()/w.getframerate(); ch=w.getnchannels()
    except Exception:
        import soundfile as sf
        i=sf.info(f"{sys.argv[1]}/{f}.wav"); d=i.duration; ch=i.channels
    print(f,d,ch)
    assert d>5 and ch==2
P
echo "ORACLE PASS"
