#!/usr/bin/env bash
# literal: apple/dnikit @ 2f39056311d6e0fbbe4e5f73da3767a5b5070dac
# readme: README.md
set -e  # glue strict mode
source /work/.venv/bin/activate  # glue the harness venv
# choice: README.md:L9 gives only the standard PyPI install (source installs are on an external website)
pip install dnikit  # README.md:L12
