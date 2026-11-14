#!/usr/bin/env bash
# Reproducible setup for openai/gpt-2 on CPU (TF1 code run via TF2 compat.v1).
set -euo pipefail
cd /work
[ -d gpt-2/.git ] || git clone https://github.com/openai/gpt-2 /work/gpt-2
cd /work/gpt-2

# TF 1.12 has no wheels for any Python uv can provide (>=3.8); use TF 2.15 CPU + compat.v1.
uv python install 3.11
[ -x /work/venv/bin/python ] || uv venv -p 3.11 /work/venv
export VIRTUAL_ENV=/work/venv
# regex==2017.4.5 / requests==2.21.0 / tqdm==4.31.1 pins are too old for py3.11; relax them.
uv pip install "tensorflow-cpu==2.15.1" "numpy<2" "fire>=0.1.3" regex requests tqdm

# Code patches (idempotent).
for f in src/model.py src/sample.py src/generate_unconditional_samples.py src/interactive_conditional_samples.py; do
  sed -i 's/^import tensorflow as tf$/import tensorflow.compat.v1 as tf\ntf.disable_v2_behavior()/' "$f"
done
/work/venv/bin/python - <<'PYEOF'
# 1) tf.contrib.training.HParams no longer exists in TF2: inline a minimal replacement.
p = 'src/model.py'
s = open(p).read()
old = 'from tensorflow.contrib.training import HParams\n'
new = '''class HParams(object):
    """Minimal stand-in for tf.contrib.training.HParams (removed in TF2)."""
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)

    def override_from_dict(self, values):
        self.__dict__.update(values)
        return self
'''
if old in s:
    open(p, 'w').write(s.replace(old, new))

# 2) Interactive script: exit cleanly on EOF so a prompt can be piped from stdin.
p = 'src/interactive_conditional_samples.py'
s = open(p).read()
if '_read_prompt' not in s:
    helper = '''import model, sample, encoder

def _read_prompt():
    # Exit cleanly when stdin is exhausted (e.g. prompt piped in).
    try:
        return input("Model prompt >>> ")
    except EOFError:
        print()
        raise SystemExit(0)
'''
    s = s.replace('import model, sample, encoder\n', helper, 1)
    s = s.replace('raw_text = input("Model prompt >>> ")', 'raw_text = _read_prompt()')
    open(p, 'w').write(s)
PYEOF

# Model download (documented step).
if [ ! -s models/124M/model.ckpt.data-00000-of-00001 ]; then
  /work/venv/bin/python download_model.py 124M
fi
