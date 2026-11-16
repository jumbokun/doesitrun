#!/usr/bin/env bash
# literal: modelscope/FunClip @ cdcb53fe3d4b37365178ae4f779296e72b7beb6a
# readme: README.md + docs/installation.md (README.md:L56 sends the reader to docs/installation.md for the Linux CPU recipe)
set -e  # glue strict mode
# choice: docs/installation.md:L11-L21 Linux x86-64 CPU recipe (README.md:L57-L65 has the same steps without the CPU torch pair)
# skip README.md:L58 git clone (harness clones)
cd /work/FunClip  # glue README.md:L59 implies being inside the repo
python3.12 -m venv .venv  # docs/installation.md:L14
. .venv/bin/activate  # docs/installation.md:L15
python -m pip install --index-url https://download.pytorch.org/whl/cpu   "torch==2.10.0" "torchaudio==2.10.0"  # docs/installation.md:L16-L17
python -m pip install -r requirements.txt  # docs/installation.md:L18
python -m pip check  # docs/installation.md:L19
python funclip/launch.py --help  # docs/installation.md:L20
apt-get update  # prereq docs/installation.md:L68 "install FFmpeg"
apt-get install -y ffmpeg  # prereq docs/installation.md:L68 "install FFmpeg"
