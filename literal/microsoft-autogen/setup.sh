#!/usr/bin/env bash
# literal: microsoft/autogen @ 8390985108cb1e3881f5f7297765758d8ad2540c
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L39 pip install of the packages; the test imports the installed autogen_core/agentchat/ext
pip install -U "autogen-agentchat" "autogen-ext[openai]"  # README.md:L39
# skip README.md:L46 AutoGen Studio is a no-code GUI the test does not use
