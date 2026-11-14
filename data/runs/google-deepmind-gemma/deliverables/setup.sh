#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d gemma/.git ] || git clone https://github.com/google-deepmind/gemma /work/gemma
uv venv --python 3.12 /work/venv
. /work/venv/bin/activate
uv pip install "jax[cpu]"
uv pip install -e /work/gemma
# sentencepiece>=0.2.2 ships protobuf-7 gencode, but tensorflow pins protobuf<7 -> VersionError on import
uv pip install "sentencepiece<0.2.2"
# Pre-download the checkpoint + tokenizer into the cache
python - <<'PY'
from gemma import gm
params = gm.ckpts.load_params(gm.ckpts.CheckpointPath.GEMMA3_270M_IT)
tok = gm.text.Gemma3Tokenizer()
tok.encode("hello")
print("prefetch ok")
PY
