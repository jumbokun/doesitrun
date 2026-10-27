#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d bert/.git ] || git clone https://github.com/google-research/bert /work/bert
# TF 1.x (needed for tf.contrib / TPUEstimator) only has wheels up to Python 3.7
# uv no longer ships Python 3.7, so use micromamba (conda-forge) for the interpreter
if [ ! -x /work/micromamba/bin/micromamba ]; then
  mkdir -p /work/micromamba
  curl -fsSL https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xj -C /work/micromamba bin/micromamba
fi
[ -x /work/venv/bin/python ] || /work/micromamba/bin/micromamba create -y -r /work/micromamba -p /work/venv -c conda-forge --override-channels python=3.7 pip
uv pip install --python /work/venv/bin/python "tensorflow==1.15.5" "protobuf==3.20.3" "numpy<1.19" "h5py<3"
# The official GCS zip (storage.googleapis.com/bert_models/...) now returns 403 AccessDenied.
# Fall back to Google's own HF upload of the same model and convert it to a TF1 checkpoint.
M=/work/models/uncased_L-2_H-128_A-2
if [ ! -f $M/bert_model.ckpt.index ]; then
  mkdir -p $M /work/models/hf_src
  if curl -fsSL -o /work/models/tiny.zip https://storage.googleapis.com/bert_models/2020_02_20/uncased_L-2_H-128_A-2.zip; then
    python3 -I -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" /work/models/tiny.zip $M
    rm -f /work/models/tiny.zip
  else
    echo "Official zip unavailable; using huggingface.co/google/bert_uncased_L-2_H-128_A-2"
    HF=https://huggingface.co/google/bert_uncased_L-2_H-128_A-2/resolve/30b0a37ccaaa32f332884b96992754e246e48c5f
    for f in config.json vocab.txt model.safetensors; do curl -fsSL -o /work/models/hf_src/$f $HF/$f; done
    (cd /work/models/hf_src && sha256sum -c - <<'SUMS'
508e1f01aae55d73355cbdd82609be2f43ba5a0d3428837adbe56cf8391f8b39  config.json
7fb69ad9f6866d8983183c930e33828f326470bf6ad8bbb2ad4ed957a92e9414  model.safetensors
07eced375cec144d27c900241f3e339478dec958f92fddbc551f295c992038a3  vocab.txt
SUMS
)
    cp /work/models/hf_src/vocab.txt $M/vocab.txt
    TF_CPP_MIN_LOG_LEVEL=2 /work/venv/bin/python -I /work/tools/hf_to_tf1_ckpt.py /work/models/hf_src $M
  fi
fi
ls $M
