# Source this file: activates the LatentSync CPU environment
source /work/venv/bin/activate
export HF_HOME=/work/hf_cache
export CUDA_VISIBLE_DEVICES=""
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-$(nproc)}"
cd /work/LatentSync
