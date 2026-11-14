#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
[ -d FunClip/.git ] || git clone https://github.com/modelscope/FunClip.git FunClip
cd FunClip
apt-get update -y && apt-get install -y --no-install-recommends ffmpeg
[ -d .venv ] || python3.12 -m venv .venv
. .venv/bin/activate
python -m pip install -U pip
python -m pip install --index-url https://download.pytorch.org/whl/cpu "torch==2.10.0" "torchaudio==2.10.0"
python -m pip install -r requirements.txt
python -m pip check || true
# Patch: stage 2 never sets VideoClipper.lang -> AttributeError once a match is found
grep -q "audio_clipper.lang = lang  # stage2" funclip/videoclipper.py || \
  sed -i 's/^\(\s*\)audio_clipper = VideoClipper(None)$/&\n\1audio_clipper.lang = lang  # stage2/' funclip/videoclipper.py
# Patch: video_clip() always saves to <name>_noN.mp4; make the CLI honour --output_file
grep -q "# honour output_file" funclip/videoclipper.py || python - <<'PY'
p = "funclip/videoclipper.py"; s = open(p).read()
anchor = "            clip_video_file, message, srt_clip = audio_clipper.video_clip(dest_text, start_ost, end_ost, state, dest_spk=dest_spk)\n"
assert anchor in s
s = s.replace(anchor, anchor + "            if clip_video_file and output_file and os.path.abspath(clip_video_file) != os.path.abspath(output_file):  # honour output_file\n                os.replace(clip_video_file, output_file)\n                clip_video_file = output_file\n", 1)
open(p, "w").write(s)
PY
# Pre-download ASR/VAD/punc/speaker models used by videoclipper.py (lang=zh)
python - <<'PY'
# Instantiate exactly as videoclipper.py does so funasr fills its own model cache
from funasr import AutoModel
AutoModel(model="iic/speech_seaco_paraformer_large_asr_nat-zh-cn-16k-common-vocab8404-pytorch",
          vad_model="damo/speech_fsmn_vad_zh-cn-16k-common-pytorch",
          punc_model="damo/punc_ct-transformer_zh-cn-common-vocab272727-pytorch",
          spk_model="damo/speech_campplus_sv_zh-cn_16k-common", disable_update=True)
PY
mkdir -p examples
[ -s "examples/2022云栖大会_片段.mp4" ] || curl -fL --retry 3 "https://huggingface.co/spaces/R1ckShi/FunClip/resolve/main/examples/2022%E4%BA%91%E6%A0%96%E5%A4%A7%E4%BC%9A_%E7%89%87%E6%AE%B5.mp4" -o "examples/2022云栖大会_片段.mp4"
