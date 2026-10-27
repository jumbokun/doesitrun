#!/bin/bash
set -euo pipefail
cd /work
[ -d PocketFlow/.git ] || git clone https://github.com/Tencent/PocketFlow /work/PocketFlow
# Docs say Python 3.6 + TF 1.10; uv no longer ships 3.6, so get it from conda-forge via micromamba
if [ ! -x /work/conda36/bin/python ]; then
  mkdir -p /work/tools
  curl -fsSL https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xj -C /work/tools bin/micromamba
  /work/tools/bin/micromamba create -y -q -r /work/mamba -p /work/conda36 -c conda-forge python=3.6 pip
fi
[ -x /work/venv/bin/python ] || uv venv --python /work/conda36/bin/python /work/venv
uv pip install --python /work/venv/bin/python "tensorflow==1.10.0" "protobuf==3.19.6" "numpy==1.14.5" "scipy==1.1.0" "pandas==0.25.3" "pytz==2023.3" "scikit-learn==0.19.2" docopt hdfs
# CIFAR-10 binary
mkdir -p /work/data
if [ ! -f /work/data/cifar-10-batches-bin/test_batch.bin ]; then
  curl -fL --retry 10 --retry-all-errors -C - -o /work/data/cifar-10-binary.tar.gz https://www.cs.toronto.edu/~kriz/cifar-10-binary.tar.gz
  tar -xzf /work/data/cifar-10-binary.tar.gz -C /work/data
  rm -f /work/data/cifar-10-binary.tar.gz
fi
cd /work/PocketFlow
sed 's#^data_dir_local_cifar10 = None#data_dir_local_cifar10 = /work/data/cifar-10-batches-bin#' path.conf.template > path.conf
