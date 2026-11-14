#!/usr/bin/env bash
# Reproducible CPU setup for PaddleSpeech (CLI: asr + tts)
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work

apt-get update -qq
apt-get install -y -qq libsndfile1 ffmpeg

[ -d PaddleSpeech/.git ] || git clone --depth 1 https://github.com/PaddlePaddle/PaddleSpeech /work/PaddleSpeech

# Python 3.12 (system) fails: several deps (onnxoptimizer via paddle2onnx) have no cp312 wheels
# and need cmake/Python.h to build. Use uv-managed Python 3.10; --seed provides pip (paddlenlp imports it).
[ -x venv/bin/python ] || uv venv --seed -p 3.10 venv
. venv/bin/activate

# Pins for transitive deps whose newer releases break paddlenlp 2.8.1 at import time
cat > /work/constraints.txt <<'C'
paddlenlp==2.8.1
huggingface_hub<0.26
aistudio-sdk<0.3
datasets<3
setuptools<80
C

# README: pip install paddlepaddle (mirror.baidu.com returns 403 -> use PyPI); pip install pytest-runner; pip install .
uv pip install -c constraints.txt paddlepaddle pytest-runner setuptools pip
cd /work/PaddleSpeech
uv pip install -c /work/constraints.txt .
cd /work

# Pre-download models (cached in ~/.paddlespeech) by running the CLIs once
mkdir -p /work/test && cd /work/test
[ -f zh.wav ] || curl -sSLo zh.wav https://paddlespeech.cdn.bcebos.com/PaddleAudio/zh.wav
cp zh.wav /work/zh.wav
paddlespeech asr --lang zh --input zh.wav
paddlespeech tts --input "你好，欢迎使用百度飞桨深度学习框架！" --output output.wav
python -c "import soundfile as s; d,r=s.read('output.wav'); assert r>0 and len(d)>r/2; print('tts ok', d.shape, r)"
