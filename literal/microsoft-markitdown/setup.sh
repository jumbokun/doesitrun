#!/usr/bin/env bash
# literal: microsoft/markitdown @ ed178952a6672abdfd35b5f9e76a80b6cefc086e
# readme: README.md
set -e  # glue strict mode
# skip README.md:L43-L44 harness provides an activated venv (Python 3.12, within the stated 3.10-3.14)
# choice: README.md:L69 source install; the test runs the CLI against files in the clone (PyPI install at README.md:L64 is the other option)
# skip README.md:L67 git clone (harness clones)
cd /work/markitdown  # glue README.md:L68 implies being inside the repo
pip install -e 'packages/markitdown[all]'  # README.md:L69
