#!/usr/bin/env bash
# literal: openai/tiktoken @ 79dc2c0533685b893616c78160b5d9e40876e724
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L17 is the only install method the README gives (PyPI)
pip install tiktoken  # README.md:L17
