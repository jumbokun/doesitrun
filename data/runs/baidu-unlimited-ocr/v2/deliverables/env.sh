# source this file
export HF_HOME=/root/.cache/huggingface
# everything is cached and patched locally; don't let the hub pull a newer, unpatched revision
export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
source /work/.venv/bin/activate
