#!/usr/bin/env bash
# Reproducible CPU setup of PaddleSpeech (ASR + TTS CLI). Run as root.
set -euxo pipefail
cd /work

# 1. Clone
if [ ! -d PaddleSpeech/.git ]; then
  git clone --depth 1 https://github.com/PaddlePaddle/PaddleSpeech /work/PaddleSpeech
fi

# 2. Python env: uv-managed CPython 3.10 (ships its own headers, so no python3-dev needed).
#    System Python 3.12 fails: paddle2onnx -> onnxoptimizer==0.3.13 has no cp312 wheel.
#    --seed: paddle imports setuptools and paddlenlp imports pip at runtime.
if [ ! -x venv/bin/python ]; then
  uv venv --seed -p 3.10 venv
fi
. venv/bin/activate

# 3. Install paddlepaddle (CPU, PyPI; README's mirror.baidu.com returns 403) + PaddleSpeech from source.
#    Pins: paddlenlp 2.8.1 breaks with current huggingface_hub / datasets / aistudio-sdk.
cd /work/PaddleSpeech
uv pip install \
  "paddlepaddle==3.3.1" pytest-runner setuptools pip \
  . \
  "huggingface_hub<0.26" "datasets<3" "aistudio-sdk==0.2.6" \
  "paddlespeech_ctcdecoders"

# 4. Pre-download models by running both CLIs once.
mkdir -p /work/data && cd /work/data
curl -fsSL -o zh.wav https://paddlespeech.cdn.bcebos.com/PaddleAudio/zh.wav
cp zh.wav /work/zh.wav
paddlespeech asr --lang zh --input zh.wav
paddlespeech tts --input "你好，欢迎使用百度飞桨深度学习框架！" --output output.wav
python -c "import soundfile as s; i=s.info('output.wav'); assert i.frames > 24000, i; print(i)"
