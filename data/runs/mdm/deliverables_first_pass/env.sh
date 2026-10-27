# Source (do not execute) before running the project CLI:
#   source /work/env.sh
#   python -m sample.generate --model_path ./save/humanml_enc_512_50steps/model000750000.pt ...
MDM_ROOT="${MDM_ROOT:-/work/motion-diffusion-model}"
export MDM_ROOT
# shellcheck disable=SC1091
. "$MDM_ROOT/.venv/bin/activate"
export PYTHONPATH="$MDM_ROOT${PYTHONPATH:+:$PYTHONPATH}"
# The project reads ./dataset, ./body_models and ./save relative to the cwd.
if ! ls save/humanml*/model*.pt >/dev/null 2>&1; then
    cd "$MDM_ROOT"
fi
