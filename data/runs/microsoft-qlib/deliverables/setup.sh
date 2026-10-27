#!/usr/bin/env bash
# Reproduce qlib + CN daily data + LightGBM Alpha158 workflow setup (CPU only).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
QLIB_COMMIT=54355232

# System headers: Ubuntu's python3 ships without Python.h, needed to build qlib's Cython extensions.
apt-get update -qq
apt-get install -y -qq python3-dev git

# Clone (pinned to the commit that was verified)
if [ ! -d /work/qlib/.git ]; then
  git clone https://github.com/microsoft/qlib /work/qlib
fi
cd /work/qlib
git fetch -q origin || true
git checkout -q "$QLIB_COMMIT"

# Lower LightGBM threads for a 4-CPU machine (config default is 20)
sed -i 's/num_threads: 20/num_threads: 4/' examples/benchmarks/LightGBM/workflow_config_lightgbm_Alpha158.yaml

# Python env (system python 3.12 in a venv)
[ -x /work/venv/bin/python ] || uv venv -p /usr/bin/python3 /work/venv
. /work/venv/bin/activate
uv pip install pip numpy cython      # README pre-reqs for source install
uv pip install .                     # README: pip install .

# Data (README command)
python scripts/get_data.py qlib_data --target_dir ~/.qlib/qlib_data/cn_data --region cn
rm -f ~/.qlib/qlib_data/cn_data/*.zip
echo "setup done"
