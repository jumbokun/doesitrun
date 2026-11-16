#!/usr/bin/env bash
# literal: aws/chalice @ ed8eca1de220b3fc27955853a3307b8db3f751c2
# readme: README.rst
set -e  # glue strict mode
# mismatch README.rst never mentions chalice local; its quickstart only runs chalice deploy (needs AWS), so there is no documented command that serves on port 8000
