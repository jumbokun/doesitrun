#!/usr/bin/env bash
# literal: modelscope/DiffSynth-Studio @ 28638042df62d206486a8bcff3ef22973c84e414
# readme: README.md
set -e  # glue strict mode
# skip README.md:L302 git clone, the harness clones to /work/DiffSynth-Studio
cd /work/DiffSynth-Studio  # glue README.md:L303 cd DiffSynth-Studio
pip install -e .  # README.md:L304
