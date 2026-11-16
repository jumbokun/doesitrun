#!/usr/bin/env bash
# literal: google-deepmind/sonnet @ 1c3b3e4dad22de663e992107531d2966fd7904aa
# readme: README.md
set -e  # glue strict mode
source /work/.venv/bin/activate  # glue the harness venv
pip install tensorflow tensorflow-probability  # README.md:L50
pip install dm-sonnet  # README.md:L51
# mismatch examples/simple_mnist.py also needs tensorflow-datasets and absl-py, which the README never mentions
