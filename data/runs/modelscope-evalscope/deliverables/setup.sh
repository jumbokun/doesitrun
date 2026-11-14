#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d evalscope/.git ] || git clone https://github.com/modelscope/evalscope /work/evalscope
git -C evalscope checkout -q 59bb367bd8565f347266a48ac1230af0b5131b97
# Python 3.11 venv via uv (image ships 3.12; README requires >=3.11)
[ -x venv/bin/python ] || uv venv -p 3.11 /work/venv
source /work/venv/bin/activate
uv pip install -e ./evalscope
# torch is not in core deps but required for local-model (llm_ckpt) eval; CPU wheel
uv pip install torch --index-url https://download.pytorch.org/whl/cpu
# transformers 5.x breaks apply_chat_template with evalscope's pydantic messages
uv pip install 'transformers>=4.33,<5,!=4.57.2'
# accelerate required by transformers when evalscope passes device_map
uv pip install accelerate
# Pre-fetch model and dataset by running the target once
evalscope eval --model Qwen/Qwen2.5-0.5B-Instruct --datasets gsm8k --limit 5 --work-dir /tmp/evalscope_warmup
ls /tmp/evalscope_warmup/*/reports/*/gsm8k.json
