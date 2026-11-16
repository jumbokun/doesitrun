#!/usr/bin/env bash
# literal: google/yapf @ 12005095296072751e3e4c1f33a047d41b0ce18d
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L28 lists PyPI first; the test runs the yapf CLI, which either install provides
pip install yapf  # README.md:L31
