#!/usr/bin/env bash
# literal: facebookresearch/Kats @ 38a32c91cdefd9a769cc3318e948ddece1f107e5
# readme: README.md
set -e  # glue strict mode
source /work/.venv/bin/activate  # glue the harness venv
# choice: README.md:L34 only offers PyPI; the full install, not MINIMAL_KATS (L43)
pip install --upgrade pip  # README.md:L37
pip install kats  # README.md:L38
