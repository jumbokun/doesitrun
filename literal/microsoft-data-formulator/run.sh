#!/usr/bin/env bash
# literal: microsoft/data-formulator @ 5477f0e236426dc8f74a498ec400414fba7fbc0f
# readme: README.md
set -e  # glue strict mode
cd /work/data-formulator  # glue repo checkout as working directory
#= README.md:L125
nohup uvx data_formulator > /work/server.log 2>&1 &  # glue start the server from the README
for i in $(seq 1 120); do curl -s http://127.0.0.1:5567/ && break; sleep 5; done  # glue wait until ready
