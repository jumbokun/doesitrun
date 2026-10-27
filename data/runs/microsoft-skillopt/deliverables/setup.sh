#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d SkillOpt/.git ] || git clone https://github.com/microsoft/SkillOpt /work/SkillOpt
[ -x /work/venv/bin/python ] || uv venv /work/venv --python 3.12
. /work/venv/bin/activate
uv pip install -e /work/SkillOpt
python -m skillopt_sleep.experiments.run_experiment --persona researcher --assert-improves
