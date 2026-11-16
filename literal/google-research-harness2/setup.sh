#!/usr/bin/env bash
# literal: google-research/harness2 @ 6868817518876de8fd170c6a8354daca273b6191
# readme: README.md
set -e  # glue strict mode
cd /work/harness2  # glue README.md:L84 "From the repository root"
# skip README.md:L87 harness provides the venv at /work/.venv (Python 3.12)
# skip README.md:L88 harness venv is already activated
uv pip install -e '.[render]'  # README.md:L89
# skip README.md:L90 the demo command itself (the hidden test runs it)
