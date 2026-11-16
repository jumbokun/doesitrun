#!/usr/bin/env bash
# literal: apple/coreai-optimization @ e632f9fa4f0cdc6ea9ac0ea6f3bd13c34a45b62c
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L16 lists the PyPI package first; the test imports coreai_opt from the venv (src layout)
pip install coreai-opt  # README.md:L16
