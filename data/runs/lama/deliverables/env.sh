# Source (do not execute) this file before running bin/predict.py:
#     source /work/env.sh
# It activates the python 3.11 venv built by /work/setup.sh and exports the two
# variables the README asks for (TORCH_HOME / PYTHONPATH).

export LAMA_HOME=/work/lama

# shellcheck disable=SC1091
. /work/venv/bin/activate

export TORCH_HOME="$LAMA_HOME"
export PYTHONPATH="$LAMA_HOME${PYTHONPATH:+:$PYTHONPATH}"

# The README runs the predictor as `python3 bin/predict.py` from the repo root.
# If the caller is somewhere else, move there so that relative path works; if
# they are already in the repo (or any dir that has bin/predict.py), stay put.
if [ ! -f bin/predict.py ]; then
    cd "$LAMA_HOME" || true
fi
