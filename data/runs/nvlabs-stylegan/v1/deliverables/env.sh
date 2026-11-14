# Source this file: activates the Python 3.7 / TF 1.15 environment for StyleGAN.
export PATH="/work/conda/bin:$PATH"
export PYTHONPATH="/work/stylegan${PYTHONPATH:+:$PYTHONPATH}"
export CUDA_VISIBLE_DEVICES=""
export TF_CPP_MIN_LOG_LEVEL=1
cd /work/stylegan 2>/dev/null || true
