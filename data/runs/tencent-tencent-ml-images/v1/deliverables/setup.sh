#!/bin/bash
set -euxo pipefail
cd /work
[ -d tencent-ml-images ] || git clone https://github.com/Tencent/tencent-ml-images /work/tencent-ml-images
# Python 2.7 is not available via apt/uv on Ubuntu 24.04 -> use micromamba (conda-forge)
mkdir -p /opt/mamba/bin
if [ ! -x /opt/mamba/bin/micromamba ]; then
  curl -fsSL https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xj -C /opt/mamba bin/micromamba
fi
export MAMBA_ROOT_PREFIX=/opt/mamba/root
[ -x /opt/mamba/envs/py27/bin/python ] || /opt/mamba/bin/micromamba create -y -p /opt/mamba/envs/py27 -c conda-forge python=2.7 pip
/opt/mamba/envs/py27/bin/python -m pip install --no-cache-dir --prefer-binary "tensorflow==1.15.0" "numpy==1.16.6" "protobuf==3.17.3" "grpcio==1.39.0" "h5py==2.10.0"
chmod +x /work/tencent-ml-images/data/tfrecord.py /work/tencent-ml-images/data/tfrecord.sh
/opt/mamba/envs/py27/bin/python -c "import tensorflow as tf; print(tf.__version__)"
# tfrecord.py has shebang #!/usr/bin/python (Python 2); Ubuntu 24.04 has no /usr/bin/python
[ -e /usr/bin/python ] || ln -s /opt/mamba/envs/py27/bin/python /usr/bin/python
