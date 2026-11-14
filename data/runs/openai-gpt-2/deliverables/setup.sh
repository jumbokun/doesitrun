#!/usr/bin/env bash
# Reproduce GPT-2 (124M) CPU setup from scratch. Run as root.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
CONDA=/opt/miniforge
ENV=/opt/gpt2env
REPO=/work/gpt-2

mkdir -p /work
if [ ! -d "$REPO/.git" ]; then
  git clone https://github.com/openai/gpt-2.git "$REPO"
fi

# Python 3.6 (needed for TF 1.x wheels) via Miniforge; uv has no CPython <3.8.
if [ ! -x "$CONDA/bin/conda" ]; then
  curl -fsSL -o /tmp/miniforge.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
  bash /tmp/miniforge.sh -b -p "$CONDA"
  rm -f /tmp/miniforge.sh
fi
if [ ! -x "$ENV/bin/python" ]; then
  "$CONDA/bin/conda" create -y -p "$ENV" python=3.6
fi

# TF 1.12 (as documented) lacks tf.sort used by src/sample.py; 1.15.5 is the last 1.x.
"$ENV/bin/pip" install --no-cache-dir tensorflow==1.15.5
cd "$REPO"
"$ENV/bin/pip" install --no-cache-dir -r requirements.txt

# Exit cleanly when stdin hits EOF instead of crashing with EOFError.
"$ENV/bin/python" - <<'PY'
p = "src/interactive_conditional_samples.py"
s = open(p).read()
old = '            raw_text = input("Model prompt >>> ")\n            while not raw_text:\n                print(\'Prompt should not be empty!\')\n                raw_text = input("Model prompt >>> ")\n'
new = '            try:\n                raw_text = input("Model prompt >>> ")\n                while not raw_text:\n                    print(\'Prompt should not be empty!\')\n                    raw_text = input("Model prompt >>> ")\n            except EOFError:\n                print()\n                return\n'
if "except EOFError" not in s:
    assert old in s, "patch target not found"
    open(p, "w").write(s.replace(old, new))
PY

"$ENV/bin/python" download_model.py 124M
echo "setup complete"
