#!/usr/bin/env bash
# literal: google/langextract @ 0e441bf77ddc3119dd0aa413322959234dd84ee5
# readme: README.md
set -e  # glue strict mode
source /work/.venv/bin/activate  # glue the harness venv
# choice: README.md:L203-L215 From Source, basic install (test runs code from the clone)
# skip README.md:L211 git clone (the harness clones)
cd /work/langextract  # glue README.md:L212 cd langextract
pip install -e .  # README.md:L215
curl -fsSL https://ollama.com/install.sh | sh  # prereq README.md:L407 "Install Ollama"
ollama pull gemma2:2b  # README.md:L407
