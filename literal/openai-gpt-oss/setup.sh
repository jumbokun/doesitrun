#!/usr/bin/env bash
# literal: openai/gpt-oss @ 277020131d524f06bed5f66b694a92ed7f6e5224
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L176-L188 Ollama section (the only CPU-capable path); 20b variant
curl -fsSL https://ollama.com/install.sh | sh  # prereq README.md:L178 "installing Ollama"
ollama pull gpt-oss:20b  # README.md:L182
