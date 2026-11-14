#!/usr/bin/env bash
# Reproduces the CPU-only Protenix setup from scratch.
set -euo pipefail
cd /work

# Python.h is needed to build scikit-learn-extra from source (no wheel for py3.12)
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq python3-dev

[ -d /work/Protenix ] || git clone https://github.com/bytedance/Protenix /work/Protenix

[ -d /work/venv ] || uv venv -p 3.12 /work/venv
source /work/venv/bin/activate
# Install CPU torch first so the pinned torch==2.7.1 requirement is satisfied without CUDA wheels
uv pip install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 \
    --index-url https://download.pytorch.org/whl/cpu
uv pip install -e /work/Protenix

source /work/env.sh

# Warm-up prediction: downloads the model checkpoint and CCD data into $PROTENIX_ROOT_DIR
mkdir -p /work/test
cat > /work/test/in.json <<'JSON'
[{"name":"ubq","covalent_bonds":[],"sequences":[{"proteinChain":{"count":1,"sequence":"MQIFVKTLTGKTITLEVEPSDTIENVKAKIQDKEGIPPDQQRLIFAGKQLEDGRTLSDYNIQKESTLHLVLRLRGG"}}]}]
JSON
cd /work/Protenix
protenix pred -i /work/test/in.json -o /work/test/out -n protenix_base_default_v1.0.0 \
    --use_msa false -d fp32 -c 4 -p 20 -e 1 --trimul_kernel torch --triatt_kernel torch \
    > /work/test/setup_pred.log 2>&1
ls /work/test/out/ubq/seed_101/predictions/
