#!/usr/bin/env bash
# literal: microsoft/SkillOpt @ 45f65ca04f5f6713bca7b9797b495696ba812751
# readme: README.md (+ docs/guide/installation.md, which README.md:L16 names for installation)
set -e  # glue strict mode
# skip docs/guide/installation.md:L38 git clone, the harness clones
cd /work/SkillOpt  # glue docs/guide/installation.md:L39 implies being inside the clone
# choice: source checkout (L35) since the test runs code from the clone
python -m pip install -e .  # docs/guide/installation.md:L40
