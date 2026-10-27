# Source this (do not execute) before running the project.
export PATH="/usr/local/cuda/bin:${PATH}"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"
# shellcheck disable=SC1091
source /work/venv/bin/activate
cd /work/stylegan2-ada-pytorch
