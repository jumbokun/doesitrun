set -e
source /work/env.sh
cd /work/PaddleSpeech
D=$(mktemp -d /tmp/oracle.XXXXXX)
cd $D
timeout 300 wget -q -c https://paddlespeech.cdn.bcebos.com/PaddleAudio/zh.wav
test $(stat -c %s zh.wav) -gt 10000
timeout 3000 paddlespeech asr --lang zh --input zh.wav --device cpu > asr.txt 2>&1 || { cat asr.txt; exit 1; }
cat asr.txt
grep -q "我认为跑步最重要的就是给我带来了身体健康" asr.txt
timeout 3000 paddlespeech tts --input "你好，欢迎使用百度飞桨深度学习框架！" --output $D/out.wav --device cpu > tts.txt 2>&1 || { cat tts.txt; exit 1; }
test $(stat -c %s $D/out.wav) -gt 50000
head -c 4 $D/out.wav | grep -q RIFF
echo ORACLE PASS
