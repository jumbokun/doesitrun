#!/usr/bin/env bash
# literal: google/langextract @ 0e441bf77ddc3119dd0aa413322959234dd84ee5
# readme: README.md
set -e  # glue strict mode
#= README.md:L407
nohup ollama serve > /work/server.log 2>&1 &  # glue start server
for i in $(seq 1 60); do curl -s http://localhost:11434 && break; sleep 5; done  # glue wait for ready
