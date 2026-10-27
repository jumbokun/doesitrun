#!/usr/bin/env bash
# Reproduce the earshot CPU install from scratch on a fresh Ubuntu 24.04 container (run as root).
# Follows the README's documented install path; the only deviation is installing ffmpeg (see /work/NOTES.md).
set -euo pipefail

REPO=/work/earshot
VENV=$REPO/.venv
CONSTRAINTS=$(mktemp /tmp/earshot-constraints.XXXXXX.txt)

# The exact dependency set that was verified (pip freeze of the working install, torch excluded: it
# comes from the CPU wheel index below). Used as pip constraints so a re-run resolves the same thing.
cat > "$CONSTRAINTS" <<'CONSTRAINTS_EOF'
Jinja2==3.1.6
MarkupSafe==3.0.3
PyJWT==2.15.1
PyYAML==6.0.3
Pygments==2.21.0
annotated-doc==0.0.5
annotated-types==0.8.0
anyio==4.15.1
attrs==26.1.0
certifi==2026.10.23
cffi==2.1.1
charset-normalizer==3.5.2
click==8.5.0
cloudpickle==3.1.2
contourpy==1.4.0
cryptography==50.0.2
cycler==0.12.1
decorator==5.3.1
filelock==3.32.3
fonttools==4.67.0
fsspec==2026.7.0
h11==0.16.0
hf-xet==1.7.0
httpcore2==2.16.0
httpx2==2.16.0
huggingface_hub==2.3.0
idna==3.20
iniconfig==2.3.1
joblib==1.6.0
jsonschema-specifications==2025.9.1
jsonschema==4.26.0
kiwisolver==1.5.1
lazy-loader==0.6
librosa==1.0.0
llvmlite==0.50.0
markdown-it-py==4.2.0
matplotlib==3.11.2
mcp-types==2.3.0
mcp==2.3.0
mdurl==0.1.2
mpmath==1.3.0
msgpack==1.2.3
narwhals==2.27.1
networkx==3.6.1
numba==0.68.0
numpy==2.5.4
opentelemetry-api==1.45.1
packaging==26.3
pillow==13.0.0
platformdirs==4.13.5
pluggy==1.7.0
pooch==1.9.0
pycparser==3.12
pydantic==2.14.1
pydantic_core==2.50.1
pyloudnorm==0.2.0
pyparsing==3.3.3
pytest==9.1.1
python-dateutil==3.0.0
python-multipart==0.0.32
referencing==0.37.0
regex==2026.9.29
requests==2.34.2
rich==15.0.0
rpds-py==2026.9.1
safetensors==0.8.0
scikit-learn==1.9.1
scipy==1.18.1
setuptools==78.1.0
shellingham==1.5.4
six==1.17.0
soundfile==0.14.0
soxr==1.1.0
sse-starlette==3.6.0
starlette==1.10.0
sympy==1.14.0
threadpoolctl==3.7.0
tokenizers==0.23.3
tqdm==4.70.1
transformers==5.20.2
truststore==0.10.5
typer==0.27.3
typing-inspection==0.4.4
typing_extensions==4.16.0
tzdata==2026.5
urllib3==2.8.0
uvicorn==0.54.0
CONSTRAINTS_EOF

# 1. System packages. The README requires ffmpeg / ffprobe on PATH; the base image has neither.
#    python3-venv backs `python -m venv`.
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends ffmpeg python3-venv ca-certificates
command -v ffmpeg >/dev/null && command -v ffprobe >/dev/null

# 2. Clone (idempotent: an existing checkout is kept).
if [ ! -d "$REPO/.git" ]; then
  git clone https://github.com/Leonxlnx/earshot "$REPO"
fi
cd "$REPO"

# 3. Python environment, as the README's Install section describes it.
[ -x "$VENV/bin/python" ] || python3 -m venv "$VENV"
PY="$VENV/bin/python"
"$PY" -m pip install -q --upgrade pip

# CPU-only torch from PyTorch's CPU wheel index (no CUDA wheels, no GPU).
"$PY" -m pip install -q "torch==2.14.1+cpu" --index-url https://download.pytorch.org/whl/cpu \
  || "$PY" -m pip install -q torch --index-url https://download.pytorch.org/whl/cpu

# earshot with the extras the README installs. If the pinned resolution ever becomes unavailable,
# fall back to an unpinned install rather than failing the whole setup.
"$PY" -m pip install -q -e ".[mcp,llm,dev]" -c "$CONSTRAINTS" \
  || "$PY" -m pip install -q -e ".[mcp,llm,dev]"
rm -f "$CONSTRAINTS"

# 4. Models: download the two pinned checkpoints (~1.1 GB) into $REPO/.cache/hf up front, so the
#    verification run loads them from the cache instead of fetching them.
"$PY" -m earshot doctor --fetch >/dev/null

# 5. Prove the goal.
"$PY" -m earshot doctor --load | tail -4
echo "setup.sh: done"
