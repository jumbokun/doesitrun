#!/usr/bin/env bash
# literal: apple/game-center-tools @ 2104310fbfca0f0fe49a034150b683e47e82984c
# readme: README.md (+ README_genrulesinput.md)
set -e  # glue strict mode
# choice: README.md:L6 links README_testrules.md, which gives the only install step (L25)
pip install requests  # prereq README_testrules.md:L25 "requests"
