#!/usr/bin/env bash
set -euxo pipefail
cd /work
[ -d PaddleSeg/.git ] || git clone --depth 1 https://github.com/PaddlePaddle/PaddleSeg PaddleSeg
# opencv runtime libs
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 unzip
# paddlepaddle 2.x has no py3.12 wheels -> use python 3.10 venv
uv venv --python 3.10 /work/venv
. /work/venv/bin/activate
uv pip install "paddlepaddle==2.6.2" "numpy<2" setuptools
cd PaddleSeg
uv pip install -r requirements.txt
uv pip install -e .
mkdir -p data
if [ ! -d data/optic_disc_seg ]; then
  curl -fL -o /tmp/optic_disc_seg.zip https://paddleseg.bj.bcebos.com/dataset/optic_disc_seg.zip
  unzip -q /tmp/optic_disc_seg.zip -d data
  rm -f /tmp/optic_disc_seg.zip
fi
# pre-fetch the pretrained backbone used by the quick_start config (otherwise fetched at train time)
if [ ! -f /root/.paddleseg/pretrained_model/PP_STDCNet2/model.pdparams ]; then
  mkdir -p /root/.paddleseg/pretrained_model
  curl -fL -o /tmp/PP_STDCNet2.tar.gz https://bj.bcebos.com/paddleseg/dygraph/PP_STDCNet2.tar.gz
  tar -xzf /tmp/PP_STDCNet2.tar.gz -C /root/.paddleseg/pretrained_model
  rm -f /tmp/PP_STDCNet2.tar.gz
fi
python -c "import paddle; paddle.utils.run_check(); import paddleseg; print(paddleseg.__version__)"
