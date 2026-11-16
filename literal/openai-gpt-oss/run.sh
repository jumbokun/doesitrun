#!/usr/bin/env bash
# literal: openai/gpt-oss @ 277020131d524f06bed5f66b694a92ed7f6e5224
# readme: README.md
set -e  # glue strict mode
# mismatch README never says ollama serve; its only start command is ollama run, an interactive prompt
#= README.md:L183
nohup ollama run gpt-oss:20b > /work/server.log 2>&1 &  # glue start server
for i in $(seq 1 60); do curl -s http://127.0.0.1:11434 && break; sleep 5; done  # glue wait for ready
