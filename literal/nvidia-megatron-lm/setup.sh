#!/usr/bin/env bash
# literal: NVIDIA/Megatron-LM @ c71687a40a302ca51917f85f963afee73a8fb8ce
# readme: README.md
set -e  # glue strict mode
source /work/.venv/bin/activate  # glue the harness venv
# choice: README.md:L34 clone and install from source rather than PyPI L31, because the test runs tools/preprocess_data.py from the clone
# skip README.md:L37 the harness clones the repo
uv pip install torch  # prereq README.md:L26 "PyTorch"
cd /work/Megatron-LM  # glue README.md:L38 inside the clone
uv pip install -e .  # README.md:L39
