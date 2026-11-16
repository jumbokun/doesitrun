#!/usr/bin/env bash
# literal: openai/whisper @ 86098128c0b4f24f0e2aa2994de830614b474227
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L22 lists the PyPI release first; the test runs the whisper CLI on tests/jfk.flac from the clone
apt-get update  # prereq README.md:L36 "apt update"
apt-get install -y ffmpeg  # prereq README.md:L32 "ffmpeg"
pip install -U openai-whisper  # README.md:L22
