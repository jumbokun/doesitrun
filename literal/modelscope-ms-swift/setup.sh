#!/usr/bin/env bash
# literal: modelscope/ms-swift @ f63220b5026556b47c1e9835a8101e0ad7cd10f2
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L139-L144 "install from source" (the test runs the clone); pip install ms-swift is listed first but installs from PyPI
# skip README.md:L140 git clone, the harness clones to /work/ms-swift
cd /work/ms-swift  # glue README.md:L141 cd ms-swift
pip install -e .  # README.md:L144
