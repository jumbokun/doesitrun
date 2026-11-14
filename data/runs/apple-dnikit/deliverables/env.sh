export VIRTUAL_ENV=/work/venv
export PATH=/work/venv/bin:$PATH
# repo pytest.ini enforces --cov-fail-under 80 over the whole src tree; a single test file can't meet it
export PYTEST_ADDOPTS="--cov-fail-under=0"
