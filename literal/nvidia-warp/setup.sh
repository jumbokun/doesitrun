#!/usr/bin/env bash
# literal: NVIDIA/warp @ b3044050e8f2c4550fd358672ad5e72683459ae9
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L66 PyPI is the first listed install; the test needs the examples extra (README.md:L93-L96)
pip install warp-lang[examples]  # README.md:L96
