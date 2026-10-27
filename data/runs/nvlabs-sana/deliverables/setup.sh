#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d Sana/.git ] || git clone https://github.com/NVlabs/Sana /work/Sana
[ -d venv ] || uv venv --python 3.12 /work/venv
export VIRTUAL_ENV=/work/venv PATH=/work/venv/bin:$PATH
uv pip install --python /work/venv/bin/python --index-url https://download.pytorch.org/whl/cpu torch torchvision
uv pip install --python /work/venv/bin/python "diffusers>=0.32.0" transformers accelerate sentencepiece protobuf safetensors pillow huggingface_hub
export HF_HOME=/work/hf_cache
python -c "from huggingface_hub import snapshot_download; snapshot_download('Efficient-Large-Model/Sana_600M_512px_diffusers')"
