#!/usr/bin/env bash
# literal: google-research/text-to-text-transfer-transformer @ 42909aa15d1fbd16c69333aa474a00ae8ed9fde4
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L161 is the only install method the README gives (PyPI)
pip install t5[gcp]  # README.md:L161
