# Source this (do not execute) before running earshot:  . /work/env.sh
# Activates the repo venv, so `python`, `python -m earshot` and the `earshot` CLI resolve to it.
VENV=/work/earshot/.venv
if [ -f "$VENV/bin/activate" ]; then
  # shellcheck disable=SC1091
  . "$VENV/bin/activate"
else
  PATH="$VENV/bin:$PATH"; export PATH
fi
# Models live in <repo>/.cache (earshot's default for a source checkout); set it explicitly so the
# cache is found no matter which directory earshot is started from.
EARSHOT_HOME=/work/earshot/.cache; export EARSHOT_HOME
