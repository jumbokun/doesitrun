#!/usr/bin/env bash
# literal: apple/game-center-tools @ 2104310fbfca0f0fe49a034150b683e47e82984c
# readme: README.md (+ README_genrulesinput.md)
set -e  # glue strict mode
# mismatch README.md and README_genrulesinput.md give no install steps; the script is called as genrulesinput.py, the test runs python3 scripts/genrulesinput.py
