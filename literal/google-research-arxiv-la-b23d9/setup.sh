#!/usr/bin/env bash
# literal: google-research/arxiv-latex-cleaner @ 1bc61c148cb72a42c5769b91af7e1ea52de3a5bf
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L35-L47 source install; the test runs the cleaner from the clone (PyPI install at README.md:L23 is the first listed alternative)
# skip README.md:L38 git clone (harness clones)
cd /work/arxiv-latex-cleaner  # glue README.md:L39 implies being inside the repo
# skip README.md:L40 runs the tool itself; the hidden test runs it
python setup.py install  # README.md:L46
