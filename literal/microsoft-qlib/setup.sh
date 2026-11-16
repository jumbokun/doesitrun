#!/usr/bin/env bash
# literal: microsoft/qlib @ 54355232463878d2eebb91fe0ee5fa7fa1f5976c
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L212-L226 install from source; the test runs scripts/ and examples/ from the clone (PyPI install at README.md:L207 is the other option)
pip install numpy  # README.md:L218
pip install --upgrade cython  # README.md:L219
# skip README.md:L224 git clone (harness clones)
cd /work/qlib  # glue README.md:L224 implies being inside the repo
pip install .  # README.md:L225
# choice: README.md:L235-L240 community data source, first listed (the official dataset is stated as disabled)
wget https://github.com/chenditc/investment_data/releases/latest/download/qlib_bin.tar.gz  # README.md:L236
mkdir -p ~/.qlib/qlib_data/cn_data  # README.md:L237
tar -zxvf qlib_bin.tar.gz -C ~/.qlib/qlib_data/cn_data --strip-components=1  # README.md:L238
rm -f qlib_bin.tar.gz  # README.md:L239
