#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends libosmesa6 libosmesa6-dev libgl1 libglu1-mesa libegl1 libglib2.0-0 libsm6 libxext6 libxrender1
cd /work
[ -d AnimatedDrawings ] || git clone https://github.com/facebookresearch/AnimatedDrawings.git
cd AnimatedDrawings
uv python install 3.8.13 || uv python install 3.8
[ -d /work/venv ] || uv venv --python 3.8 /work/venv
. /work/venv/bin/activate
uv pip install pip setuptools wheel
uv pip install -e .
# headless config for char1 + dab
cat > /work/AnimatedDrawings/examples/config/mvc/export_gif_char1_mesa.yaml <<'YAML'
scene:
  ANIMATED_CHARACTERS:
    - character_cfg: examples/characters/char1/char_cfg.yaml
      motion_cfg: examples/config/motion/dab.yaml
      retarget_cfg: examples/config/retarget/fair1_ppf.yaml
view:
  USE_MESA: True
controller:
  MODE: video_render
  OUTPUT_VIDEO_PATH: ./video.gif
YAML
