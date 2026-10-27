# Source this file: activates the Megatron-LM CPU venv
source /work/venv/bin/activate
export PYTHONPATH=/work/Megatron-LM${PYTHONPATH:+:$PYTHONPATH}
export CUDA_VISIBLE_DEVICES=""
export TOKENIZERS_PARALLELISM=false
export GPT2_TOKENIZER_DIR=/work/gpt2
cd /work/Megatron-LM
