gpu_used() { nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -1; }
