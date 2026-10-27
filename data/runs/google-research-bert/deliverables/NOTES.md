# BERT extract_features.py on CPU with BERT-Tiny

## What broke
1. **Python / TF version**: the code uses TF 1.x APIs (`tf.contrib.tpu.TPUEstimator`, `tf.flags`, ...). `requirements.txt` says `tensorflow >= 1.11.0`, which today pulls in TF 2.x, and TF 2.x drops `tf.contrib`. TF 1.15 wheels only exist up to Python 3.7, and the sandbox's `uv` doesn't offer CPython 3.7.
2. **Dead model link**: `https://storage.googleapis.com/bert_models/2020_02_20/uncased_L-2_H-128_A-2.zip` (and the other `bert_models` URLs) now return HTTP 403 AccessDenied for anonymous callers.

## What I changed (no repo code patched)
- Got Python 3.7 from conda-forge using micromamba, in the env `/work/venv`. Then installed `tensorflow==1.15.5` (CPU), `protobuf==3.20.3`, `numpy<1.19` and `h5py<3` with `uv pip`.
- `setup.sh` still tries the official zip first. If that fails, it downloads Google's own HF upload `google/bert_uncased_L-2_H-128_A-2` (pinned revision, sha256-checked: config.json, vocab.txt, model.safetensors). `/work/tools/hf_to_tf1_ckpt.py` then converts it into a TF1 checkpoint (`bert_model.ckpt.*`) with the variable names `modeling.py` expects, and writes `bert_config.json`. When `extract_features.py` runs, all variables log as `*INIT_FROM_CKPT*`.
- `env.sh` puts `/work/venv/bin` first on PATH, sets `BERT_BASE_DIR=/work/models/uncased_L-2_H-128_A-2`, and turns off the GPU and TF log noise.

## Usage
    source /work/env.sh; cd /work/bert
    python extract_features.py --input_file=in.txt --output_file=out.jsonl \
      --vocab_file=$BERT_BASE_DIR/vocab.txt --bert_config_file=$BERT_BASE_DIR/bert_config.json \
      --init_checkpoint=$BERT_BASE_DIR/bert_model.ckpt --layers=-1,-2 --max_seq_length=128 --batch_size=8
