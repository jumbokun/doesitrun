#!/usr/bin/env bash
# literal: bytedance/Sa2VA @ c2c28a683627c6900e9652c253e205e9ecf4e563
# readme: README.md, projects/sa2va/README.md
set -e  # glue strict mode
# skip projects/sa2va/README.md:L58 uv installer: uv is already in the start state
cd /work/Sa2VA  # glue projects/sa2va/README.md:L62 setup_env.sh is at the repo root
bash setup_env.sh sa2va latest  # projects/sa2va/README.md:L62
