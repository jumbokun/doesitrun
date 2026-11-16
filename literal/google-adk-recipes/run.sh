#!/usr/bin/env bash
# literal: google/adk-recipes @ e05958ea5c6577c84e04c0f5063fe1e8544f5b00
# readme: README.md (L32 -> core/python/ambient-expense-agent/README.md)
set -e  # glue strict mode
cd /work/adk-recipes/core/python/ambient-expense-agent  # glue core/python/ambient-expense-agent/README.md:L115
#= core/python/ambient-expense-agent/README.md:L142
nohup make dev > /work/server.log 2>&1 &  # glue start the backend from the README
for i in $(seq 1 120); do curl -s http://localhost:8080/list-apps && break; sleep 5; done  # glue wait until ready
