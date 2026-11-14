# source this file
export HF_HOME="${HF_HOME:-/root/.cache/huggingface}"
source /work/.venv/bin/activate
# keep using the locally patched (CPU-compatible) remote code; don't re-fetch from the Hub
export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
