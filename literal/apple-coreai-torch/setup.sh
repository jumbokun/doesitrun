#!/usr/bin/env bash
# literal: apple/coreai-torch @ 31908ce231d0794dd966f9fae610da5f95041288
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L20 pip install is listed first; uv sync (L27) would build a project .venv that env.sh cannot activate under the glue rules
pip install coreai-torch  # README.md:L21
