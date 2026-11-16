#!/usr/bin/env bash
# literal: modelscope/modelscope @ 987d79f0029f6438197a8093a406848467336dfd
# readme: README.md
set -e  # glue strict mode
# skip README.md:L229-L230 conda is only suggested (L226); L225 says "ModelScope supports python3.7 and above", so the harness venv (3.12) qualifies
source /work/.venv/bin/activate  # glue the harness venv
pip install torch  # prereq README.md:L233 "PyTorch or TensorFlow can be installed separately"
# choice: README.md:L249-L251 nlp extra (the test runs an NLP pipeline)
pip install modelscope[nlp] -f https://modelscope.oss-cn-beijing.aliyuncs.com/releases/repo.html  # README.md:L251
