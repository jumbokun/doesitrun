#!/usr/bin/env bash
# Reproducible CPU setup for FunClip CLI demo.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work

if [ ! -d FunClip/.git ]; then
  git clone https://github.com/modelscope/FunClip.git FunClip
fi
cd FunClip

# Patch CLI stage 2 (missing self.lang; honor --output_file name)
python3 - <<'PY'
p = 'funclip/videoclipper.py'
s = open(p).read()
a = "        audio_clipper = VideoClipper(None)\n"
if "audio_clipper = VideoClipper(None)\n        audio_clipper.lang = lang" not in s:
    assert s.count(a) == 1
    s = s.replace(a, a + "        audio_clipper.lang = lang\n")
b = "            clip_video_file, message, srt_clip = audio_clipper.video_clip(dest_text, start_ost, end_ost, state, dest_spk=dest_spk)\n"
if "honor an explicit --output_file" not in s:
    assert s.count(b) == 1
    s = s.replace(b, b + """            # video_clip appends a _no{N} suffix; honor an explicit --output_file
            if output_file is not None and clip_video_file is not None and clip_video_file != output_file:
                os.replace(clip_video_file, output_file)
                clip_video_file = output_file
""")
open(p, 'w').write(s)
PY

# Python env per docs/installation.md (Linux CPU recipe)
[ -x .venv/bin/python ] || python3.12 -m venv .venv
. .venv/bin/activate
python -m pip install -q --upgrade pip
python -m pip install -q --index-url https://download.pytorch.org/whl/cpu "torch==2.10.0" "torchaudio==2.10.0"
python -m pip install -q -r requirements.txt
python -m pip check

# Example video. The README URL (.../2022云栖大会_片段.mp4) serves a clip that does not
# contain the README's --dest_text; that text is in 2022云栖大会_片段2.mp4 of the same Space.
mkdir -p examples
HF=https://huggingface.co/spaces/R1ckShi/FunClip/resolve/main/examples
curl -sSfL --retry 3 "$HF/2022%E4%BA%91%E6%A0%96%E5%A4%A7%E4%BC%9A_%E7%89%87%E6%AE%B52.mp4" -o "examples/2022云栖大会_片段.mp4"
curl -sSfL --retry 3 "$HF/2022%E4%BA%91%E6%A0%96%E5%A4%A7%E4%BC%9A_%E7%89%87%E6%AE%B5.mp4" -o "examples/2022云栖大会_片段_readme_url.mp4"

# Pre-download the ModelScope models used by stage 1 (zh)
python - <<'PY'
from funasr import AutoModel
AutoModel(model="iic/speech_seaco_paraformer_large_asr_nat-zh-cn-16k-common-vocab8404-pytorch",
          vad_model="damo/speech_fsmn_vad_zh-cn-16k-common-pytorch",
          punc_model="damo/punc_ct-transformer_zh-cn-common-vocab272727-pytorch",
          spk_model="damo/speech_campplus_sv_zh-cn_16k-common", disable_update=True)
PY
echo "FunClip setup complete"
