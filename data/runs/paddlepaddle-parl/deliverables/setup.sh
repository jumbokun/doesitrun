#!/usr/bin/env bash
# Reproduces the PARL QuickStart (CartPole) CPU environment from scratch.
set -euxo pipefail
cd /work
if [ ! -d /work/PARL/.git ]; then
  git clone https://github.com/PaddlePaddle/PARL /work/PARL
fi
git -C /work/PARL checkout -q 89fc1ba5aa508f49fd84c4ae4a05c4a61954ac41
# Python 3.9: parl pins grpcio==1.37.0 / pyzmq==22.3.0, which have no py3.12 wheels.
rm -rf /work/venv
uv venv -p 3.9 /work/venv
source /work/venv/bin/activate
# parl pins protobuf<=3.20.0 but every paddlepaddle on PyPI needs protobuf>=3.20.2 -> override.
echo 'protobuf==3.20.3' > /work/overrides.txt
uv pip install --override /work/overrides.txt \
  paddlepaddle==2.6.2 gym==0.26.2 pygame "numpy<2" "setuptools<70" /work/PARL
python -c "import parl, paddle, gym; print(parl.__version__, paddle.__version__, gym.__version__)"
