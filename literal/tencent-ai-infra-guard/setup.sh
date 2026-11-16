#!/usr/bin/env bash
# literal: Tencent/AI-Infra-Guard @ 777859d766ad52ac8693186e82305fccff192da2
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L126 pip install of the infra scanner; the Docker routes (L85-L110) deploy the whole platform and are not the CLI scan the test runs
pip install aig-infra-scan  # README.md:L126
# skip README.md:L127 runs the scan itself; the hidden test runs it
