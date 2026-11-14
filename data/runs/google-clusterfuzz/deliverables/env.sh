# Source this file: activates the ClusterFuzz pipenv virtualenv.
export PIPENV_VENV_IN_PROJECT=1
export PYTHONUNBUFFERED=1
export CLUSTERFUZZ_DIR=/work/clusterfuzz
if [ -f "$CLUSTERFUZZ_DIR/.venv/bin/activate" ]; then
  source "$CLUSTERFUZZ_DIR/.venv/bin/activate"
fi
cd "$CLUSTERFUZZ_DIR"
