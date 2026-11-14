#!/usr/bin/env bash
# Reproduces the dnikit (core) setup: CPU-only, Python 3.10 venv at /work/venv.
set -euo pipefail
cd /work
if [ ! -d /work/dnikit/.git ]; then
  git clone https://github.com/apple/dnikit /work/dnikit
fi
# dnikit classifiers stop at Python 3.10; use a uv-managed 3.10 interpreter
[ -x /work/venv/bin/python ] || uv venv -p 3.10 /work/venv
uv pip install -p /work/venv/bin/python /work/dnikit/src/dnikit pytest
# pytest.ini addopts require dev plugins (mypy/flake8/cov with an 80% coverage gate)
# that break when running a single test file; drop those dev-only options.
python3 - <<'PY'
import re, pathlib
p = pathlib.Path("/work/dnikit/pytest.ini")
s = p.read_text()
for opt in ["    --mypy\n", "    --flake8\n", "    --junit-xml=junit.xml\n", "    --cov src\n",
            "    --cov-fail-under 80\n", "    --cov-report html:coverage\n"]:
    s = s.replace(opt, "")
s = s.replace("flake8-max-line-length = 100\n", "")
p.write_text(s)
PY
/work/venv/bin/python -c "from dnikit.introspectors import Duplicates, DimensionReduction, Familiarity; from dnikit.base import pipeline, Batch; from dnikit.samples import StubProducer; print('dnikit OK')"
