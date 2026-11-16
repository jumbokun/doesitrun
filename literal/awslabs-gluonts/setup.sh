#!/usr/bin/env bash
# literal: awslabs/gluonts @ d60556ca71167a3ec1ea807b491dd982d1de2112
# readme: README.md
set -e  # glue strict mode
source /work/.venv/bin/activate  # glue the harness venv
# choice: README.md:L24 is the first listed install (PyPI with torch extra); the development install L35 is "for development"
uv pip install "gluonts[torch]"  # README.md:L24
