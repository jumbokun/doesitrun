#!/usr/bin/env bash
# Reproducible CPU setup for FunASR SenseVoiceSmall + fsmn-vad + cam++ example.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
if [ ! -d /work/FunASR/.git ]; then
  git clone https://github.com/modelscope/FunASR /work/FunASR
fi
# ffmpeg is optional (torchaudio loads wav fine) but silences the backend notice
apt-get update -qq && apt-get install -y -qq ffmpeg >/dev/null || true
[ -x /work/venv/bin/python ] || uv venv -p python3.12 /work/venv
. /work/venv/bin/activate
# README: "pip install torch torchaudio" -- use the CPU wheel index (no GPU here, much smaller)
uv pip install torch==2.14.1 torchaudio==2.11.0 --index-url https://download.pytorch.org/whl/cpu
# README "From source": pip install -e ./
uv pip install -e /work/FunASR
mkdir -p /work/test
cat > /work/test/demo.py <<'PYEOF'
import sys
from funasr import AutoModel
from funasr.utils.postprocess_utils import rich_transcription_postprocess
wav = sys.argv[1] if len(sys.argv) > 1 else "/work/FunASR/runtime/funasr_api/asr_example.wav"
model = AutoModel(model="iic/SenseVoiceSmall", vad_model="fsmn-vad", spk_model="cam++", device="cpu")
result = model.generate(input=wav, batch_size_s=300)
for seg in result[0]["sentence_info"]:
    print(f"[{seg['start']/1000:.1f}s] Speaker {seg['spk']}: {rich_transcription_postprocess(seg['sentence'])}")
PYEOF
# Pre-download models from ModelScope by running the README example once
cd /tmp && python /work/test/demo.py /work/FunASR/runtime/funasr_api/asr_example.wav
