#!/usr/bin/env bash
# literal: microsoft/pyright @ baf130b28df75cebff171f29e4f4c43d0414ae22
# readme: README.md, docs/build-debug.md
set -e  # glue strict mode
# README.md:L17 sends the reader to the docs; the repo's build doc is docs/build-debug.md
apt-get update  # prereq docs/build-debug.md:L4 "nodejs"
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -  # prereq docs/build-debug.md:L4 "version 16.x"
apt-get install -y nodejs  # prereq docs/build-debug.md:L4 "nodejs"
# mismatch docs/build-debug.md never says how to install pnpm, which L6 and L12 need
cd /work/pyright  # glue docs/build-debug.md:L5 main directory of cloned source
pnpm run install:all  # docs/build-debug.md:L6
cd packages/pyright  # glue docs/build-debug.md:L11
pnpm run build  # docs/build-debug.md:L12
