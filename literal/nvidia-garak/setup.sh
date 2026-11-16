#!/usr/bin/env bash
# literal: NVIDIA/garak @ 892779207cbc38f65a738ef9cbdfbc1e83aa0b55
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L50 standard pip install is listed first; the conda clone path (L66-L76) is the alternative
python -m pip install -U garak  # README.md:L55
