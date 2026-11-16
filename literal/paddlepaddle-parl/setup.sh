#!/usr/bin/env bash
# literal: PaddlePaddle/PARL @ 89fc1ba5aa508f49fd84c4ae4a05c4a61954ac41
# readme: README.md, docs/installation_guide.md
set -e  # glue strict mode
# choice: README.md:L94 points to the Detailed Installation Guide; follow it (CPU paddlepaddle)
uv venv --seed --clear --python 3.10 /work/.venv  # prereq docs/installation_guide.md:L6 "3.7 - 3.10"
source /work/.venv/bin/activate  # prereq docs/installation_guide.md:L6 "3.7 - 3.10"
pip install paddlepaddle  # docs/installation_guide.md:L11
pip install numpy==1.23.5  # docs/installation_guide.md:L26
pip install parl gym  # docs/installation_guide.md:L32
pip install pygame  # prereq examples/QuickStart/README.md:L10 "pygame"
# mismatch the test runs examples from the clone while the guide installs parl from PyPI
