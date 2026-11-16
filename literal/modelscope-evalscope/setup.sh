#!/usr/bin/env bash
# literal: modelscope/evalscope @ 95d873680be8023bf6630f7f12e9791f6fbbf4bf
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L181 pip install is the only listed install (Python >= 3.11 per L179, harness venv is 3.12)
pip install evalscope  # README.md:L182
