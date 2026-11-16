#!/usr/bin/env bash
# literal: apple/coremltools @ a207b1a3452eafe02f2d870f486287834af2c82d
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L35 pip install from PyPI; the source path (BUILDING.md) is a conda build.sh for macOS/Zsh
pip install coremltools  # README.md:L35
# mismatch the test also imports torch and scikit-learn, which the README never installs
