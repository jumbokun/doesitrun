#!/usr/bin/env bash
set -euo pipefail
cd /work
[ -d stylegan3/.git ] || git clone https://github.com/NVlabs/stylegan3 /work/stylegan3
cd /work/stylegan3
git checkout -q c233a91
# CPU fallback: gen_images.py hard-codes cuda
sed -i "s/device = torch.device('cuda')$/device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')/" gen_images.py
grep -q "torch.cuda.is_available() else 'cpu'" gen_images.py
cd /work
uv venv --clear --python 3.10 /work/venv
uv pip install --python /work/venv/bin/python --index-url https://download.pytorch.org/whl/cpu torch==2.2.2
uv pip install --python /work/venv/bin/python "numpy<2" "setuptools<70" "click>=8.0" pillow scipy requests tqdm ninja matplotlib imageio
# pre-download pretrained network into the dnnlib cache
export DNNLIB_CACHE_DIR=/work/cache/dnnlib
URL=https://api.ngc.nvidia.com/v2/models/nvidia/research/stylegan3/versions/1/files/stylegan3-r-afhqv2-512x512.pkl
cd /work/stylegan3
/work/venv/bin/python -c "import dnnlib,sys; dnnlib.util.open_url(sys.argv[1]).close()" "$URL"
