#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d ClearerVoice-Studio/.git ] || git clone https://github.com/modelscope/ClearerVoice-Studio /work/ClearerVoice-Studio
# ffmpeg is optional (only for non-wav formats); install it for completeness
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq ffmpeg libsndfile1 >/dev/null || echo "ffmpeg install failed (optional)"
[ -x /work/venv/bin/python ] || uv venv -p 3.12 /work/venv
. /work/venv/bin/activate
# CPU-only torch wheels (avoid pulling multi-GB CUDA wheels on a GPU-less box)
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.14.1 torchaudio==2.11.0 torchvision==0.29.1
cd /work/ClearerVoice-Studio/clearvoice
uv pip install -e .
# Pre-fetch the FRCRN_SE_16K checkpoint (auto-download path) and smoke-test enhancement
python - <<'PY'
from clearvoice import ClearVoice
cv = ClearVoice(task='speech_enhancement', model_names=['FRCRN_SE_16K'])
out = cv(input_path='samples/input.wav', online_write=False)
cv.write(out, output_path='samples/output_FRCRN_SE_16K.wav')
PY
