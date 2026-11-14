# Source this file: activates the t5 environment.
source /work/venv/bin/activate
export HF_HOME=/work/hf_cache
export NO_GCE_CHECK=true           # skip GCE metadata probe when reading public gs://t5-data vocab
export TF_CPP_MIN_LOG_LEVEL=2
export CUDA_VISIBLE_DEVICES=""
