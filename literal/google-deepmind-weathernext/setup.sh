#!/usr/bin/env bash
# literal: google-deepmind/weathernext @ f2f2c5117d2f864e2d5e7c2f9f220db5e1049dd3
# readme: README.md
set -e  # glue strict mode
pip install git+https://github.com/google-deepmind/weathernext.git@v0.3.0  # README.md:L137
# mismatch README.md:L142-L144 only links the weights bucket; the test downloads weights and data itself
