#!/usr/bin/env bash
# literal: modelscope/FunASR @ c1e3018bf0b16ac10d40fe7cf902cafd624ee4dd
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L47 "CPU-only installs can use the default PyPI wheels"; PyPI install listed first (From source at L163 is the alternative)
pip install torch torchaudio  # README.md:L48
pip install funasr  # README.md:L49
