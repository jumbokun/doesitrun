#!/usr/bin/env bash
# Reproduce MedicalNet CPU setup for `python train.py --ci_test`.
set -euo pipefail
cd /work
if [ ! -d MedicalNet/.git ]; then
  git clone https://github.com/Tencent/MedicalNet /work/MedicalNet
fi
cd /work/MedicalNet
git checkout -q 20f76aa

# Python env: README's Python 3.7 + pinned numpy/scipy/nibabel conflict with torch>=2.6 in requirements.txt
uv venv -q --allow-existing -p 3.11 /work/venv
uv pip install -q --python /work/venv/bin/python --index-url https://download.pytorch.org/whl/cpu "torch==2.6.0"
uv pip install -q --python /work/venv/bin/python "numpy==2.2.6" "nibabel==5.5.0" "scipy==1.17.1"

# Compatibility patches for nibabel>=5 (get_data removed) and scipy (ndimage.interpolation deprecated)
sed -i 's/= data\.get_data()/= np.asanyarray(data.dataobj)/; s/= label\.get_data()/= np.asanyarray(label.dataobj)/' datasets/brains18.py
sed -i 's/ndimage\.interpolation\.zoom/ndimage.zoom/' datasets/brains18.py train.py test.py
echo "setup done"
