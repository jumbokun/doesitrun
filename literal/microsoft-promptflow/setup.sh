#!/usr/bin/env bash
# literal: microsoft/promptflow @ 33a68c9d3cf349d7fdfad1f41969af27543c0406
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L53 recommends python>=3.9, <=3.11, so use 3.11 instead of the harness 3.12 venv
uv venv --clear --python 3.11 /work/.venv  # prereq README.md:L53 "python>=3.9, <=3.11 is recommended"
source /work/.venv/bin/activate  # prereq README.md:L53 "python>=3.9, <=3.11 is recommended"
pip install promptflow promptflow-tools  # README.md:L56
