#!/usr/bin/env bash
# Reproduces the t5 + HfPyTorchModel (CPU) environment from scratch.
set -euxo pipefail
cd /work
export HF_HOME=/work/hf_cache

REPO=/work/text-to-text-transfer-transformer
if [ ! -d "$REPO/.git" ]; then
  git clone https://github.com/google-research/text-to-text-transfer-transformer "$REPO"
fi

# Patch: HfPyTorchModel.predict never appended EOS to encoded inputs.
if ! grep -q 'vocabs\["inputs"\].eos_id' "$REPO/t5/models/hf_model.py"; then
  git -C "$REPO" apply /work/scripts/hf_model_eos.patch 2>/dev/null || python3 - "$REPO/t5/models/hf_model.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''        lambda x: {"inputs": tf.cast(vocabs["inputs"].encode_tf(x), tf.int64)},'''
new = '''        lambda x: {
            "inputs": tf.concat(
                [
                    tf.cast(vocabs["inputs"].encode_tf(x), tf.int64),
                    [tf.constant(vocabs["inputs"].eos_id, tf.int64)],
                ],
                axis=0,
            )
        },'''
assert s.count(old) == 1, "patch target not found"
open(p, "w").write(s.replace(old, new))
PY
fi

# Python 3.11: pandas<2.0 (required by t5) has no 3.12 wheels and fails to build.
uv venv --allow-existing -p 3.11 /work/venv
export VIRTUAL_ENV=/work/venv

cat > /work/constraints.txt <<'C'
numpy<2
tensorflow==2.15.1
tensorflow-text==2.15.0
tensorflow-metadata==1.15.0
sentencepiece==0.2.0
setuptools<81
C

uv pip install -e "$REPO[gcp]" torch "setuptools<81" \
  -c /work/constraints.txt \
  --index-strategy unsafe-best-match \
  --extra-index-url https://download.pytorch.org/whl/cpu

# Pre-download the t5-base checkpoint.
/work/venv/bin/python -c "import transformers as t; t.T5ForConditionalGeneration.from_pretrained('t5-base'); t.AutoTokenizer.from_pretrained('t5-base')"
