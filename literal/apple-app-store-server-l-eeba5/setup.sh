#!/usr/bin/env bash
# literal: apple/app-store-server-library-python @ e5ffded5c978668fdc1a0bba1c747c7a8017fd80
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L17-L19 gives pip from PyPI (the only plain install); the test imports the installed package
pip install app-store-server-library  # README.md:L18
