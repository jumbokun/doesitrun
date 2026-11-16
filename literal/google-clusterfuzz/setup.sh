#!/usr/bin/env bash
# literal: google/clusterfuzz @ fb2712c4018ae75ded9ee72770028c50fe1184d4
# readme: README.md, docs/getting-started/local_instance.md
set -e  # glue strict mode
# README.md:L39 sends the reader to the docs; the repo copy is docs/getting-started/local_instance.md
# skip docs/getting-started/local_instance.md:L36-L39 devcontainer path needs Docker Desktop and VS Code, not a plain CPU Linux box
# mismatch the doc lists no separate install step on the non-devcontainer path; butler run_server installs dependencies itself
