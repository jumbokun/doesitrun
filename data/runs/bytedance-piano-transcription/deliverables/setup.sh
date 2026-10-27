#!/usr/bin/env bash
set -euo pipefail
cd /work
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ffmpeg wget >/dev/null
[ -d piano_transcription/.git ] || git clone https://github.com/bytedance/piano_transcription /work/piano_transcription
[ -d venv ] || uv venv -p 3.12 venv
. venv/bin/activate
uv pip install torch --index-url https://download.pytorch.org/whl/cpu
uv pip install piano_transcription_inference audioread "librosa==0.9.2"
CK="$HOME/piano_transcription_inference_data/note_F1=0.9677_pedal_F1=0.9186.pth"
mkdir -p "$(dirname "$CK")"
if [ ! -s "$CK" ] || [ "$(stat -c%s "$CK")" -lt 160000000 ]; then
  wget -q -O "$CK" 'https://zenodo.org/record/4034264/files/CRNN_note_F1%3D0.9677_pedal_F1%3D0.9186.pth?download=1'
fi
python -c "import piano_transcription_inference; print('ok')"
