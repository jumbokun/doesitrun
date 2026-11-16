#!/usr/bin/env bash
# literal: aws/aws-cli @ 1e29ade904104db39b204e32edb566b008140f23
# readme: README.rst
set -e  # glue strict mode
# choice: README.rst:L46-L59 lists only binary installers (macOS/Linux zip/Windows); the goal is an install from the checkout, so the "CLI Dev Version" section (README.rst:L381) is used
cd /work/aws-cli && git checkout v2  # placeholder README.rst:L402 <path_to_awscli> => /work/aws-cli
pip install -r requirements-dev-lock.txt  # README.rst:L403
pip install -e .  # README.rst:L404
