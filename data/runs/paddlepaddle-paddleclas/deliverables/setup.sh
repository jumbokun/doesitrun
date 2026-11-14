#!/usr/bin/env bash
# Reproducible CPU setup for PaddleClas (release/2.6 default branch) whl inference.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work

# System libs needed by opencv-python (libGL / glib)
apt-get update -qq
apt-get install -y -qq libgl1 libglib2.0-0t64 >/dev/null

# Clone
if [ ! -d /work/PaddleClas/.git ]; then
  git clone https://github.com/PaddlePaddle/PaddleClas /work/PaddleClas
fi

# Python 3.11: requirements pin numpy==1.24.4 for py<3.13, which has no py3.12 wheel
# and fails to build from source on 3.12 (distutils removed).
rm -rf /work/venv
uv venv -p 3.11 /work/venv
. /work/venv/bin/activate

# Paddle 2.6.x: the ResNet50 inference model downloaded by the whl is in the
# Paddle 2.x .pdmodel format; with Paddle 3.x the predictor looks for inference.json.
# setuptools: uv venvs have none, and paddle imports it at import time.
uv pip install paddlepaddle==2.6.2 setuptools

# Patch: ppcls/* uses absolute `import ppcls...`, which is unresolvable once the
# repo root is installed as the `paddleclas` package. Append package dir to sys.path.
cd /work/PaddleClas
if ! grep -q "_root = os.path.dirname" __init__.py; then
python3 - <<'PY'
p = '__init__.py'
s = open(p).read()
s = s.replace("__all__ = ['PaddleClas']\n",
    "import os\nimport sys\n\n"
    "# ppcls uses absolute `import ppcls...`; make it resolvable when installed as `paddleclas`\n"
    "_root = os.path.dirname(os.path.abspath(__file__))\n"
    "if _root not in sys.path:\n    sys.path.append(_root)\n\n"
    "__all__ = ['PaddleClas']\n", 1)
open(p, 'w').write(s)
PY
fi

# Documented local install
uv pip install -e .

# Pre-download the pretrained ResNet50 inference model (~/.paddleclas) and smoke test
paddleclas --model_name=ResNet50 --infer_imgs=docs/images/inference_deployment/whl_demo.jpg
