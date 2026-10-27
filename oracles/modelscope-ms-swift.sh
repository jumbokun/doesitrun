set -e
source /work/env.sh
cd /work/ms-swift
export CUDA_VISIBLE_DEVICES=""
O=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 3000 swift sft \
  --model Qwen/Qwen2.5-0.5B-Instruct \
  --tuner_type lora \
  --dataset 'swift/self-cognition#60' \
  --torch_dtype float32 \
  --num_train_epochs 1 \
  --max_steps 8 \
  --per_device_train_batch_size 1 \
  --gradient_accumulation_steps 2 \
  --learning_rate 1e-4 \
  --lora_rank 8 --lora_alpha 32 \
  --target_modules all-linear \
  --split_dataset_ratio 0 \
  --save_steps 8 --logging_steps 2 \
  --max_length 512 \
  --dataloader_num_workers 0 \
  --model_author swift --model_name swift-robot \
  --output_dir $O/out 2>&1 | tee $O/train.log
CK=$(ls -d $(find $O/out -type d -name 'checkpoint-*' | sort) | tail -1)
test -n "$CK"
test -s $CK/adapter_model.safetensors
test -s $CK/adapter_config.json
test $(stat -c %s $CK/adapter_model.safetensors) -gt 100000
cat > $O/q.jsonl <<'J'
{"messages": [{"role": "user", "content": "Who are you?"}]}
{"messages": [{"role": "user", "content": "What is 1+1?"}]}
J
timeout 1500 swift infer --adapters $CK --val_dataset $O/q.jsonl --max_new_tokens 64 \
  --temperature 0 --max_batch_size 1 --result_path $O/res.jsonl 2>&1 | tee $O/infer.log
test -s $O/res.jsonl
python - $O/res.jsonl <<'P'
import json,sys
rows=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
assert len(rows)==2, rows
for r in rows:
    s=json.dumps(r)
    assert 'response' in r or 'messages' in r, r
    resp=r.get('response') or r['messages'][-1]['content']
    assert isinstance(resp,str) and len(resp.strip())>2, r
print(rows)
P
echo ORACLE PASS
