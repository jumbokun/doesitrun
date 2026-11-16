#!/usr/bin/env bash
# literal: google/clusterfuzz @ fb2712c4018ae75ded9ee72770028c50fe1184d4
# readme: README.md, docs/getting-started/local_instance.md
set -e  # glue strict mode
# README.md:L39 sends the reader to the docs; the repo copy is docs/getting-started/local_instance.md
# skip docs/getting-started/local_instance.md:L36-L39 devcontainer path needs Docker Desktop and VS Code, not a plain CPU Linux box
# choice: README.md:L39 sends the reader to the docs; docs/getting-started/prerequisites.md lists Python 3.11 and the dependency script
uv venv --seed --clear --python 3.11 /work/.venv  # prereq docs/getting-started/prerequisites.md:L62 "Download Python 3.11"
source /work/.venv/bin/activate  # prereq docs/getting-started/prerequisites.md:L62 "Download Python 3.11"
cd /work/clusterfuzz  # glue docs/getting-started/prerequisites.md:L93 runs from the clone
local/install_deps.bash  # docs/getting-started/prerequisites.md:L93
