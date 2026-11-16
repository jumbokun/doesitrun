#!/usr/bin/env bash
# literal: google/clusterfuzz @ fb2712c4018ae75ded9ee72770028c50fe1184d4
# readme: README.md, docs/getting-started/local_instance.md
set -e  # glue strict mode
cd /work/clusterfuzz  # glue run from the checkout
#= docs/getting-started/local_instance.md:L54
nohup python butler.py run_server --bootstrap > /work/server.log 2>&1 &  # glue start the doc server command in the background
for i in $(seq 1 240); do curl -sf http://localhost:9000/ && break; sleep 5; done  # glue wait until ready
