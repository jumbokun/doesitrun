# source /work/env.sh
source /work/venv/bin/activate
export LAYERNORM_TYPE=torch   # fused layernorm is a CUDA-only JIT kernel
cd /work/Protenix
