#!/usr/bin/env bash
# literal: NVIDIA/SkillSpector @ c81615007d40e86051a302a3cf897f8a05264928
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L56 "From source" (the test runs the clone); README.md:L46 uv tool install is the first alternative but installs from GitHub, not the clone
# skip README.md:L60 git clone, the harness clones to /work/SkillSpector
cd /work/SkillSpector  # glue README.md:L61 implies being inside the clone
uv venv .venv && source .venv/bin/activate  # README.md:L64
make install  # README.md:L68
