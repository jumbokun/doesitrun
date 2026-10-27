#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
[ -d GiantMIDI-Piano/.git ] || git clone https://github.com/bytedance/GiantMIDI-Piano /work/GiantMIDI-Piano
apt-get update
apt-get install -y --no-install-recommends ffmpeg libsndfile1 wget
uv venv --python 3.12 /work/venv
source /work/venv/bin/activate
uv pip install --index-url https://download.pytorch.org/whl/cpu torch
# requirements.txt pins (bs4 4.9.1, nltk 3.5) are old but install; youtube-dl not needed for transcription
uv pip install -r /work/GiantMIDI-Piano/requirements.txt "librosa==0.9.2" audioread mido setuptools
# Pre-download transcription checkpoint (library would otherwise fetch it via wget on first use)
CKPT="$HOME/piano_transcription_inference_data/note_F1=0.9677_pedal_F1=0.9186.pth"
mkdir -p "$(dirname "$CKPT")"
if [ ! -s "$CKPT" ] || [ "$(stat -c%s "$CKPT")" -lt 160000000 ]; then
  curl -sSL --retry 5 -o "$CKPT" "https://zenodo.org/record/4034264/files/CRNN_note_F1%3D0.9677_pedal_F1%3D0.9186.pth?download=1"
fi
# importing dataset.py triggers nltk data downloads; do it once here
cd /work/GiantMIDI-Piano && PYTHONWARNINGS=ignore python -c "import torch, librosa, piano_transcription_inference, dataset; print('ok')"
