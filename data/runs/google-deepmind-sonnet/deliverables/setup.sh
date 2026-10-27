#!/usr/bin/env bash
# Reproduce Sonnet setup (CPU only) from scratch.
set -euo pipefail
cd /work
[ -d sonnet/.git ] || git clone https://github.com/google-deepmind/sonnet /work/sonnet
[ -d venv ] || uv venv -p 3.12 /work/venv
. /work/venv/bin/activate
# README: pip install tensorflow tensorflow-probability; pip install dm-sonnet
# (installed from the clone). importlib_resources is an undeclared tfds dependency.
uv pip install \
  tensorflow==2.21.0 tensorflow-probability==0.25.0 \
  tensorflow-datasets==4.9.10 absl-py importlib_resources \
  /work/sonnet
# Pre-download MNIST into the tfds cache.
python -c "import tensorflow_datasets as tfds; tfds.load('mnist', split=['train','test'])"
