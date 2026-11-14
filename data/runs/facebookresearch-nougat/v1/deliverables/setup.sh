#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d /work/nougat/.git ] || git clone https://github.com/facebookresearch/nougat /work/nougat
export UV_PYTHON_INSTALL_DIR=/work/.uv-python
uv venv --python 3.10 /work/venv --clear
source /work/venv/bin/activate
# CPU-only torch first, then the repo with constraints for packages whose newer releases break nougat
uv pip install --index-url https://download.pytorch.org/whl/cpu "torch==2.2.2" "torchvision==0.17.2"
cat > /work/constraints.txt <<'C'
transformers==4.38.2
timm==0.5.4
albumentations==1.3.1
pypdfium2==4.30.0
numpy<2
lightning==2.2.5
setuptools<81
C
uv pip install -c /work/constraints.txt -e /work/nougat
# also a fpdf-free PDF generator for self-test isn't needed; pre-download default checkpoint
python - <<'P'
from nougat.utils.checkpoint import get_checkpoint
print(get_checkpoint(None, model_tag="0.1.0-small"))
P
# nougat downloads the nltk 'words' corpus at runtime; fetch it up front
python -c "import nltk; nltk.download('words', quiet=True)"
echo "setup complete"
