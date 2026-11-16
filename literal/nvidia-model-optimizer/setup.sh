#!/usr/bin/env bash
# literal: NVIDIA/Model-Optimizer @ 6c85409916c66e778c4569b17efca9de577622da
# readme: README.md
set -e  # glue strict mode
source /work/.venv/bin/activate  # glue the harness venv
# choice: README.md:L88 install from source in editable mode, because the test runs from the clone
# skip README.md:L92 the harness clones the repo
cd /work/Model-Optimizer  # glue README.md:L93 implies being inside the clone
pip install -e .[dev]  # README.md:L95
