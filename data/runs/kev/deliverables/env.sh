# Source this (not execute) before running /work/run.sh.
# Activates the uv-managed virtualenv that holds Python 3.13, torch 2.8.0+cu128
# and the editable `kev` package.

export KEV_REPO=/work/kev
export KEV_RUN=jaredpalmer/kev-0.8b
export KEV_PORT=8009

# Model/tokenizer cache created by /work/setup.sh, kept out of $HOME so it is
# the same no matter which user runs the server.
export HF_HOME=/work/hf-cache

# Quieter, non-interactive downloads if anything still has to be fetched.
export HF_HUB_DISABLE_PROGRESS_BARS=1
export TOKENIZERS_PARALLELISM=false

if [ -f "$KEV_REPO/.venv/bin/activate" ]; then
    # shellcheck disable=SC1091
    . "$KEV_REPO/.venv/bin/activate"
else
    echo "env.sh: $KEV_REPO/.venv is missing; run /work/setup.sh first" >&2
fi
