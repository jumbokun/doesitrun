#!/usr/bin/env bash
# literal: aws/chalice @ ed8eca1de220b3fc27955853a3307b8db3f751c2
# readme: README.rst
set -e  # glue strict mode
# skip README.rst:L130 python3 -m venv .venv  (the harness provides /work/.venv)
source /work/.venv/bin/activate  # glue the harness venv
# choice: README.rst gives only PyPI install, not install from the clone
python3 -m pip install chalice  # README.rst:L135
# skip README.rst:L155 AWS credentials are for chalice deploy; the test is offline
cd /work  # glue project is created next to the clone
chalice new-project helloworld  # README.rst:L174
cd helloworld  # README.rst:L179
