# sourced, not executed
export CUDA_HOME=/usr/local/cuda
export PATH="$CUDA_HOME/bin:$PATH"
export HF_HOME=/work/hf-cache
export TORCH_CUDA_ARCH_LIST=12.0
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
# shellcheck disable=SC1091
source /work/venv/bin/activate
