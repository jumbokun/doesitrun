#!/usr/bin/env bash
# literal: google/adk-python @ c6586f19ab8a2bb8b53e70041633b10858d9902e
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L100 Development Version, because the test runs workflow samples that exist only in the clone's main; Stable (L75) is the first listed
pip install git+https://github.com/google/adk-python.git@main  # README.md:L105
