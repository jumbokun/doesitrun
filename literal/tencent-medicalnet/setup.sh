#!/usr/bin/env bash
# literal: Tencent/MedicalNet @ 20f76aaab5cac8056eaf50b79ed97c09dbfbd3bd
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L91 says install Python 3.7.0; uv installs the 3.7 line (3.7.0 exactly is not published)
uv venv --python 3.7 /work/.venv  # prereq README.md:L91 "Install Python 3.7.0"
source /work/.venv/bin/activate  # prereq README.md:L91 "Install Python 3.7.0"
cd /work/MedicalNet  # glue README.md:L92 requirements.txt is in the repo root
pip install -r requirements.txt  # README.md:L92
# skip README.md:L137 git clone, the harness clones to /work/MedicalNet
# skip README.md:L143 mv of the Google Drive data and pretrained models zip; the --ci_test demo uses the bundled toy_data
# skip README.md:L145 unzip of the Google Drive zip, same reason
