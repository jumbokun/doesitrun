set -e
source /work/env.sh
cd /work/PaddleSpeech
D=$(mktemp -d /tmp/oracle.XXXXXX)
cd $D
# README.md:288 uses `wget -c`; the container only has curl, so fetch the same file with curl.
timeout 300 curl -fsSL --retry 5 --retry-all-errors -o zh.wav https://paddlespeech.cdn.bcebos.com/PaddleAudio/zh.wav
test $(stat -c %s zh.wav) -gt 10000
head -c 4 zh.wav | grep -q RIFF
# README.md:299 + expected transcript at README.md:59 / 309 (punctuation not required).
timeout 3000 paddlespeech asr --lang zh --input zh.wav --device cpu > asr.txt 2>&1 || { cat asr.txt; exit 1; }
cat asr.txt
grep -q "我认为跑步最重要的就是给我带来了身体健康" asr.txt
# README.md:323
timeout 3000 paddlespeech tts --input "你好，欢迎使用百度飞桨深度学习框架！" --output $D/out.wav --device cpu > tts.txt 2>&1 || { cat tts.txt; exit 1; }
tail -5 tts.txt
test $(stat -c %s $D/out.wav) -gt 50000
head -c 4 $D/out.wav | grep -q RIFF
python - $D/out.wav <<'P'
import sys, wave, numpy as np
w = wave.open(sys.argv[1])
n, sr, sw = w.getnframes(), w.getframerate(), w.getsampwidth()
dur = n / float(sr)
x = np.frombuffer(w.readframes(n), dtype={2: np.int16, 4: np.int32}[sw]).astype(np.float64)
print("tts wav", sr, "Hz", round(dur, 2), "s", "peak", x.max() if x.size else 0)
# 17-character sentence: anything between 1 s and 30 s is plausible speech; it must not be silent.
assert 1.0 < dur < 30.0, dur
assert x.size and np.abs(x).max() > 1000 and x.std() > 100, (np.abs(x).max(), x.std())
P
echo ORACLE PASS
