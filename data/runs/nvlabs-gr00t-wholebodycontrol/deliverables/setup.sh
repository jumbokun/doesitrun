#!/usr/bin/env bash
# Reproduce the CPU-only motionbricks setup from scratch.
set -euo pipefail
cd /work
REPO_COMMIT=1e1ec4f5f27e6c3e03048f693bd7c60cce04afda
if [ ! -d GR00T-WholeBodyControl/.git ]; then
  git lfs install --skip-repo || true
  # Repo .lfsconfig already excludes motionbricks/out/** (the big checkpoints); skip all LFS smudge
  # since training on synthetic data only needs the small plain-git yaml/npy/pickle files.
  GIT_LFS_SKIP_SMUDGE=1 git clone https://github.com/NVlabs/GR00T-WholeBodyControl.git
fi
git -C GR00T-WholeBodyControl checkout -q "$REPO_COMMIT"

# README uses conda + python 3.10; use uv venv with python 3.10 instead (conda not in image)
[ -x /work/venv/bin/python ] || uv venv -p 3.10 /work/venv
. /work/venv/bin/activate

cat > /tmp/motionbricks-lock.txt <<'LOCK'
absl-py==2.5.1
adam-atan2-pytorch==0.4.1
aiohappyeyeballs==2.7.1
aiohttp==3.14.5
aiosignal==1.4.0
annotated-doc==0.0.6
annotated-types==0.8.0
antlr4-python3-runtime==4.9.3
anyio==4.16.0
async-timeout==5.0.1
attrs==26.1.0
click==8.5.1
colorlog==6.12.0
contourpy==1.3.2
cycler==0.12.1
einops==0.8.2
einx==0.4.3
etils==1.13.0
evdev==1.9.3
exceptiongroup==1.3.1
filelock==4.1.0
fonttools==4.65.0
frozendict==2.5.1
frozenlist==1.8.0
fsspec==2026.9.0
glfw==2.11.0
h11==0.16.0
hf-xet==1.8.0
httpcore2==2.14.0
httpx2==2.14.0
huggingface-hub==2.4.0
hydra-core==1.3.8
idna==3.20
importlib-resources==7.1.0
jinja2==3.1.6
kiwisolver==1.5.1
lightning-utilities==0.15.3
loguru==0.8.0
markdown-it-py==4.3.0
markupsafe==3.0.3
matplotlib==3.10.9
mdurl==0.1.2
mpmath==1.3.0
mujoco==3.17.0
multidict==7.1.0
networkx==3.4.2
numpy==2.2.6
omegaconf==2.3.1
packaging==26.3
pillow==12.3.0
propcache==0.5.4
pydantic==2.14.3
pydantic-core==2.50.4
pygments==2.21.0
pynput==1.8.2
pyopengl==3.1.10
pyparsing==3.3.3
python-dateutil==3.0.0
python-xlib==0.33
pytorch-lightning==2.6.6
pyyaml==6.0.3
regex==2026.9.29
rich==15.0.0
safetensors==0.8.0
scipy==1.15.3
setuptools==78.1.0
shellingham==1.5.4
six==1.17.0
sympy==1.14.0
tokenizers==0.23.3
tomli==2.5.0
torch==2.14.1+cpu
torch-einops-utils==0.2.6
torchmetrics==1.9.0
tqdm==4.70.1
transformers==5.20.2
truststore==0.10.5
typer==0.29.1
typing-extensions==4.16.0
typing-inspection==0.4.5
tzdata==2026.6
vector-quantize-pytorch==1.34.0
websockets==16.1.1
yarl==1.25.1
zipp==4.1.2
LOCK
# CPU-only torch wheel (avoid pulling multi-GB CUDA wheels)
uv pip install --index-url https://pypi.org/simple --extra-index-url https://download.pytorch.org/whl/cpu \
  --index-strategy unsafe-best-match -r /tmp/motionbricks-lock.txt
cd /work/GR00T-WholeBodyControl/motionbricks
uv pip install --index-url https://pypi.org/simple --extra-index-url https://download.pytorch.org/whl/cpu \
  --index-strategy unsafe-best-match -e . pynput python-xlib
python -c "import torch, motionbricks; print('torch', torch.__version__, 'cuda', torch.cuda.is_available())"
