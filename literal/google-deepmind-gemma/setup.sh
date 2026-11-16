#!/usr/bin/env bash
# literal: google-deepmind/gemma @ 9e1f74131ba9d45e5fe6ae7bb3941d9f2abb39c3
# readme: README.md
set -e  # glue strict mode
pip install jax  # prereq README.md:L22 "Install JAX for CPU"
pip install gemma  # README.md:L27
