#!/usr/bin/env bash
# literal: amazon-science/chronos-forecasting @ 1224fafa91e1ecd6674f5204066b159e40b5e4a1
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L59 is the only install method the README gives (PyPI)
pip install chronos-forecasting  # README.md:L59
