#!/usr/bin/env bash
# Reproduce m3-agent setup for README Memorization step 6 (visualization.py) on CPU.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
W=/work; R=$W/m3-agent
mkdir -p $W && cd $W

# 1. clone
[ -d $R/.git ] || git clone https://github.com/ByteDance-Seed/m3-agent $R
cd $R

# 2. system packages (ffmpeg is listed in the repo's setup.sh)
apt-get update && apt-get install -y ffmpeg

# 3. python env: code uses `int | None` syntax -> needs Python >=3.10 (README hints 3.9.2)
uv python install 3.10
[ -d $W/venv ] || uv venv --python 3.10 $W/venv
. $W/venv/bin/activate
uv pip install -r requirements.txt
# CPU builds of the torch versions pinned in the repo's setup.sh (flash-attn/vllm skipped: GPU-only, not needed here)
uv pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cpu
uv pip install numpy==1.26.4 onnxruntime==1.22.1 insightface==0.7.3 hdbscan==0.8.40 pydub==0.25.1 moviepy==2.1.2 httpx==0.23.0 \
    setuptools_scm torchdiffeq resampy x_transformers peft==0.15.2 accelerate==0.34.2 scipy

# 4. speakerlab + eres2netv2 checkpoint (README Memorization step 4; imported unconditionally by mmagent)
if [ ! -d $R/speakerlab ]; then
  rm -rf /tmp/3D-Speaker
  git clone --depth 1 https://github.com/modelscope/3D-Speaker /tmp/3D-Speaker
  cp -r /tmp/3D-Speaker/speakerlab $R/speakerlab
fi
mkdir -p $R/models $R/logs
[ -s $R/models/pretrained_eres2netv2.ckpt ] || curl -fL --retry 5 -o $R/models/pretrained_eres2netv2.ckpt \
  https://www.modelscope.cn/models/iic/speech_eres2netv2_sv_zh-cn_16k-common/resolve/master/pretrained_eres2netv2.ckpt

# 5. patch: voice_processing hard-codes .to('cuda') at import time -> fall back to CPU
sed -i "s/embedding_model.to(torch.device('cuda'))/embedding_model.to(torch.device('cuda' if torch.cuda.is_available() else 'cpu'))/" mmagent/voice_processing.py
grep -q "is_available() else 'cpu'" mmagent/voice_processing.py
# patch: no display on this machine -> don't pop up face images (script's own SHOW_FACES knob)
sed -i 's/^SHOW_FACES = True/SHOW_FACES = False/' visualization.py

# 6. pre-built memory graphs (README: optional download from HF)
mkdir -p $R/data/memory_graphs
if [ ! -s $R/data/memory_graphs/robot/bedroom_01.pkl ]; then
  mkdir -p $W/dl
  [ -s $W/dl/robot.tar.gz.done ] || { curl -fL --retry 5 -C - -o $W/dl/robot.tar.gz \
    https://huggingface.co/datasets/ByteDance-Seed/M3-Bench/resolve/main/memory_graphs/robot.tar.gz && touch $W/dl/robot.tar.gz.done; }
  tar -xzf $W/dl/robot.tar.gz -C $R/data/memory_graphs
fi
ls -la $R/data/memory_graphs/robot/bedroom_01.pkl

# 7. warm-up: importing mmagent instantiates insightface FaceAnalysis, which downloads buffalo_l (~280MB) on first use
cd $R && MPLBACKEND=Agg python visualization.py --mem_path data/memory_graphs/robot/bedroom_01.pkl --clip_id 1 | grep "Clip 1 Memory"
