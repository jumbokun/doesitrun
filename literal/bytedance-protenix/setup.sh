#!/usr/bin/env bash
# literal: bytedance/Protenix @ 85767b811c40ed46e73a9b39519cf6bfca8701ba
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L49 Quick Installation from PyPI is the only install command
pip install --upgrade protenix --index-url https://pypi.org/simple  # README.md:L52
