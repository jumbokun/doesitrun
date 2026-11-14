# Source this file: activates the Protenix CPU environment
source /work/venv/bin/activate
# Fused layer-norm is a CUDA extension compiled at import time; use the pure torch one on CPU
export LAYERNORM_TYPE=torch
# Where Protenix downloads/looks for checkpoints and CCD data (defaults to $HOME)
export PROTENIX_ROOT_DIR=/root
