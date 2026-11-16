#!/usr/bin/env bash
# literal: microsoft/VibeVoice @ 16fb2cb1217c9934a886e1948ffb06120caa2df5
# readme: README.md, docs/vibevoice-realtime-0.5b.md
set -e  # glue strict mode
# skip docs/vibevoice-realtime-0.5b.md:L88 NVIDIA docker container with --gpus all (GPU-only)
# skip docs/vibevoice-realtime-0.5b.md:L97 git clone, the harness clones to /work/VibeVoice
cd /work/VibeVoice  # glue docs/vibevoice-realtime-0.5b.md:L98 cd VibeVoice/
pip install -e .[streamingtts]  # docs/vibevoice-realtime-0.5b.md:L100
