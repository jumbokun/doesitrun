#!/usr/bin/env bash
set -euxo pipefail
cd /work
[ -d ms-swift/.git ] || git clone https://github.com/modelscope/ms-swift /work/ms-swift
uv venv --allow-existing --python 3.12 /work/venv
source /work/venv/bin/activate
cd /work/ms-swift
# torch is not listed in requirements; install CPU wheels explicitly
uv pip install torch torchvision --torch-backend=cpu
uv pip install -e . --torch-backend=cpu
cd /work
export CUDA_VISIBLE_DEVICES=""
# Pre-download model (ModelScope default hub)
python -c "from modelscope import snapshot_download; print(snapshot_download('Qwen/Qwen2.5-0.5B-Instruct'))"
# Quick Start, CPU-scaled: few steps, float32
rm -rf /work/output
swift sft \
    --model Qwen/Qwen2.5-0.5B-Instruct \
    --tuner_type lora \
    --dataset 'swift/self-cognition#40' \
    --torch_dtype float32 \
    --max_steps 5 \
    --per_device_train_batch_size 1 \
    --learning_rate 1e-4 \
    --lora_rank 8 \
    --lora_alpha 32 \
    --target_modules all-linear \
    --gradient_accumulation_steps 1 \
    --save_steps 5 \
    --eval_steps 5 \
    --logging_steps 1 \
    --max_length 512 \
    --output_dir /work/output \
    --dataloader_num_workers 0 \
    --model_author swift \
    --model_name swift-robot
CKPT=$(ls -d /work/output/v*/checkpoint-* | sort -V | tail -1)
ln -sfn "$CKPT" /work/checkpoint
printf '%s\n' '{"messages": [{"role": "user", "content": "who are you?"}]}' \
  '{"messages": [{"role": "user", "content": "What is 2+3?"}]}' > /work/test.jsonl
swift infer --adapters /work/checkpoint --val_dataset /work/test.jsonl \
  --max_new_tokens 64 --temperature 0 --result_path /work/infer_result.jsonl
cat /work/infer_result.jsonl
