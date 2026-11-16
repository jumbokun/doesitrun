#!/usr/bin/env bash
# literal: google/adk-recipes @ e05958ea5c6577c84e04c0f5063fe1e8544f5b00
# readme: README.md (L32 -> core/python/ambient-expense-agent/README.md)
set -e  # glue strict mode
# skip core/python/ambient-expense-agent/README.md:L114 git clone (the harness clones)
cd /work/adk-recipes/core/python/ambient-expense-agent  # glue core/python/ambient-expense-agent/README.md:L115
# choice: core/python/ambient-expense-agent/README.md:L125 Option A (AI Studio) with a dummy key; the test needs no real model
echo "GOOGLE_API_KEY=dummy" >> .env  # placeholder core/python/ambient-expense-agent/README.md:L125 YOUR_AI_STUDIO_API_KEY => dummy
make install  # core/python/ambient-expense-agent/README.md:L142
