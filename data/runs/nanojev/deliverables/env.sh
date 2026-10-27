# Sourced (not executed) before running /work/run.sh.
NANOJEV_HOME=/work/NanoJev
NANOJEV_VENV=/work/venv
export NANOJEV_HOME NANOJEV_VENV

# shellcheck disable=SC1091
. "$NANOJEV_VENV/bin/activate"

# serve_decisions.py / predict_toy_decisions.py / train_toy_decisions.py import
# each other as flat modules, so scripts/ has to be importable from any cwd.
export PYTHONPATH="$NANOJEV_HOME/scripts${PYTHONPATH:+:$PYTHONPATH}"
export PYTHONUNBUFFERED=1

# The predictor reads only the local checkpoint; keep the Hub out of the loop.
export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export HF_HUB_DISABLE_TELEMETRY=1
