#!/usr/bin/env bash
# Reproduces the LaMa inference setup (big-lama, bin/predict.py) from scratch.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# System libs: opencv-python (pulled in by albumentations/imgaug) needs libGL + glib; unzip for the model zip
apt-get update -qq
apt-get install -y -qq libgl1 libglib2.0-0 unzip

cd /work
[ -d lama/.git ] || git clone https://github.com/advimman/lama /work/lama
cd /work/lama

# Python 3.10 venv (old pins don't build on system Python 3.12); torch cu128 for Blackwell sm_120
uv venv -p 3.10 --allow-existing /work/venv
. /work/venv/bin/activate
uv pip install torch==2.7.1 torchvision==0.22.1 --index-url https://download.pytorch.org/whl/cu128
cat > /tmp/lama-lock.txt <<'LOCK'
absl-py==2.5.1
aiohappyeyeballs==2.7.1
aiohttp==3.14.5
aiosignal==1.4.0
albumentations==0.5.2
antlr4-python3-runtime==4.8
async-timeout==5.0.1
attrs==26.1.0
braceexpand==0.1.7
cloudpickle==3.1.2
contourpy==1.3.2
cycler==0.12.1
easydict==1.9
filelock==4.1.0
fonttools==4.65.0
frozenlist==1.8.0
fsspec==2026.9.0
future==1.0.0
grpcio==1.85.1
hydra-core==1.1.0
idna==3.20
imageio==2.38.0
imgaug==0.4.0
jinja2==3.1.6
joblib==1.6.0
kiwisolver==1.5.1
kornia==0.5.0
markdown==3.10.3
markupsafe==3.0.3
matplotlib==3.10.9
mpmath==1.3.0
multidict==7.1.0
networkx==3.4.2
numpy==1.26.4
omegaconf==2.1.2
opencv-python==4.11.0.86
opencv-python-headless==4.11.0.86
packaging==26.3
pandas==2.3.3
pillow==12.3.0
propcache==0.5.4
protobuf==7.36.2
pyparsing==3.3.3
python-dateutil==3.0.0
pytorch-lightning==1.2.9
pytz==2026.6
pywavelets==1.8.0
pyyaml==6.0.3
scikit-image==0.19.3
scikit-learn==1.3.2
scipy==1.15.3
setuptools==78.1.0
shapely==2.1.2
six==1.17.0
sympy==1.14.0
tabulate==0.10.0
tensorboard==2.21.0
tensorboard-data-server==0.7.2
threadpoolctl==3.8.0
tifffile==2025.5.10
tqdm==4.70.1
typing-extensions==4.16.0
tzdata==2026.6
webdataset==1.0.2
werkzeug==3.1.9
yarl==1.25.1
LOCK
uv pip install -r /tmp/lama-lock.txt

# PyTorch>=2.6 defaults torch.load(weights_only=True); the Lightning checkpoint needs full unpickling
sed -i 's/state = torch.load(path, map_location=map_location)$/state = torch.load(path, map_location=map_location, weights_only=False)/' \
    saicinpainting/training/trainers/__init__.py
grep -q 'weights_only=False' saicinpainting/training/trainers/__init__.py

# Model download, as in README
if [ ! -f big-lama/models/best.ckpt ]; then
  rm -f big-lama.zip
  curl -fLJO https://huggingface.co/smartywu/big-lama/resolve/main/big-lama.zip
  unzip -o big-lama.zip
  rm -f big-lama.zip
fi
test -f big-lama/config.yaml && test -f big-lama/models/best.ckpt
echo "setup done"
