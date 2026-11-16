#!/usr/bin/env bash
# literal: QwenLM/Qwen-MM-Plugins @ eea016154bf6e85a9a2d45331e7ae4e786a412c1
# readme: README.md (+ docs/en/local_development.md, which README.md:L131 names for running from source)
set -e  # glue strict mode
# skip README.md:L56 guided installer installs into agent harnesses (Claude Code, Codex, ...), not a Python env
# choice: docs/en/local_development.md:L8 "Fast source loop" is the only way to run the MCP server from the clone
cd /work/Qwen-MM-Plugins  # glue docs/en/local_development.md:L5 run from the repository root
python3 -m venv .venv  # docs/en/local_development.md:L13
source .venv/bin/activate  # docs/en/local_development.md:L14
python -m pip install -e '.[core]'  # docs/en/local_development.md:L15
# mismatch the test needs the viz extras (pypdfium2, pandas, matplotlib); the doc installs only '.[core]'
