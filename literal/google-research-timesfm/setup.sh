#!/usr/bin/env bash
# literal: google-research/timesfm @ 918df02c9d366b2145bc5876135fa2131d3ed2a6
# readme: README.md
set -e  # glue strict mode
source /work/.venv/bin/activate  # glue the harness venv
# choice: README.md:L131 Local Install (source) rather than PyPI L125, because the test runs timesfm3 from the clone
# skip README.md:L133-L138 the harness clones the repo
cd /work/timesfm  # glue README.md:L137 implies being inside the clone
# skip README.md:L144-L145 uv venv + activate: the harness already provides /work/.venv
uv pip install -e .[torch]  # README.md:L148
