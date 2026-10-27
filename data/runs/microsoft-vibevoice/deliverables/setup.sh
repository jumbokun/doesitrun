#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d VibeVoice/.git ] || git clone https://github.com/microsoft/VibeVoice /work/VibeVoice
apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ffmpeg libsndfile1
[ -d /work/venv ] || uv venv --python 3.12 /work/venv
source /work/venv/bin/activate
# CPU-only torch wheels; pinned to 2.8.0 because torch>=2.9-ish weights_only unpickler rejects the voice preset .pt files
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.8.0 torchaudio==2.8.0
cd /work/VibeVoice
uv pip install pip setuptools wheel
uv pip install -e ".[streamingtts]" torch==2.8.0 torchaudio==2.8.0 --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match
export HF_HOME=/work/hf_cache
python -c "from huggingface_hub import snapshot_download; snapshot_download('microsoft/VibeVoice-Realtime-0.5B')"
# Processor also loads the Qwen2.5-0.5B tokenizer
python -c "from huggingface_hub import snapshot_download; snapshot_download('Qwen/Qwen2.5-0.5B', allow_patterns=['*.json','*.txt','merges.txt','vocab.json'])"
