#!/usr/bin/env bash
# literal: aws/serverless-application-model @ 6e52163a5760ec16a2bc84d70fd385205e2811f6
# readme: README.md
set -e  # glue strict mode
# skip README.md:L40 sam sync deploys to AWS; the hidden test saves the template and runs sam-translate itself
# choice: README.md:L86 "Setting up development environment" is the only install path for the clone
cd /work/serverless-application-model  # glue README.md:L93 implies being inside the clone
python3 -m venv .venv  # README.md:L93
source .venv/bin/activate  # README.md:L94
make init  # README.md:L100
