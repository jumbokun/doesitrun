#!/usr/bin/env bash
# Reproduces the evalscope CPU setup from scratch (non-interactive, run as root).
set -euxo pipefail
cd /work
[ -d evalscope/.git ] || git clone --depth 1 https://github.com/modelscope/evalscope /work/evalscope

# Python env (README: pip install evalscope, Python >= 3.11)
[ -x /work/venv/bin/python ] || uv venv -p 3.12 /work/venv
. /work/venv/bin/activate
uv pip install "evalscope==1.15.0"
# Not documented in README / not pulled in by evalscope:
uv pip install torch --index-url https://download.pytorch.org/whl/cpu   # needed by local (llm_ckpt) models
uv pip install accelerate                                                # needed for device_map in from_pretrained
uv pip install "transformers>=4.33,<5,!=4.57.2"                          # transformers 5.x breaks apply_chat_template w/ pydantic msgs

# Pre-fetch model and datasets (warm-up eval, limit 1)
modelscope download --model Qwen/Qwen2.5-0.5B-Instruct
evalscope eval --model Qwen/Qwen2.5-0.5B-Instruct --datasets gsm8k arc --limit 1 --work-dir /tmp/evalscope_warmup
rm -rf /tmp/evalscope_warmup
