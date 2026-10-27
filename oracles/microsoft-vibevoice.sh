set -e
source /work/env.sh
cd /work/VibeVoice
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
printf 'Hello there. This is a short test of the VibeVoice real time speech model running on a CPU.\n' > $OUT/oracle_in.txt
timeout 5400 python demo/realtime_model_inference_from_file.py --model_path microsoft/VibeVoice-Realtime-0.5B --txt_path $OUT/oracle_in.txt --speaker_name Carter --output_dir $OUT/out --device cpu
python3 - "$OUT/out" <<'PY'
import sys,glob,wave,os
fs=glob.glob(sys.argv[1]+"/*.wav")
assert fs, "no wav"
f=fs[0]
assert os.path.getsize(f)>20000, "wav too small"
w=wave.open(f); dur=w.getnframes()/w.getframerate()
print("duration",dur,"rate",w.getframerate())
assert 2<dur<60, "implausible duration"
import array
d=w.readframes(w.getnframes()); a=array.array('h',d[:len(d)//2*2])
assert max(abs(x) for x in a)>500, "silent audio"
PY
echo "ORACLE PASS"
