#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d mlx-examples/.git ] || git clone https://github.com/ml-explore/mlx-examples /work/mlx-examples
uv venv --allow-existing --python python3 /work/venv
. /work/venv/bin/activate
uv pip install -r /work/mlx-examples/mnist/requirements.txt
# On Linux the mlx wheel lacks libmlx.so; the CPU backend ships in the mlx[cpu] extra.
uv pip install "mlx[cpu]>=0.2"
# Pre-download MNIST (main.py would also do this on first run).
cd /work/mlx-examples/mnist && python -c "import mnist; mnist.mnist()"
