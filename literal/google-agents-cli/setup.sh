#!/usr/bin/env bash
# literal: google/agents-cli @ 6eedbdc2f44c388cbfc5f305eb83b9924cfefebb
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L33-L35 lists the uvx setup first; the skills-only npx variant is the alternative
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -  # prereq README.md:L29 "Node.js"
apt-get install -y nodejs  # prereq README.md:L29 "Node.js"
uvx google-agents-cli setup  # README.md:L34
# mismatch README never puts agents-cli on PATH (uvx runs it in a throwaway env); the test calls agents-cli from /work/env.sh
