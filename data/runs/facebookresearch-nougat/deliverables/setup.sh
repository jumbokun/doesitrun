#!/usr/bin/env bash
# Reproduce nougat CPU setup from scratch.
set -euxo pipefail
cd /work
[ -d nougat/.git ] || git clone https://github.com/facebookresearch/nougat /work/nougat
git -C nougat checkout 5a92920d342fb6acf05fc9b594ccb4053dbe8e7a
[ -x venv/bin/python ] || uv venv -p 3.12 /work/venv
. /work/venv/bin/activate
# CPU-only torch wheels (avoid pulling multi-GB CUDA wheels)
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.15.0 torchvision==0.29.2
# Documented install from repository, plus pypdfium2 pin: nougat uses PdfDocument.render(), removed in pypdfium2 5.x
uv pip install ./nougat "pypdfium2==4.30.0"
# Pre-download default 0.1.0-small checkpoint (same location the CLI uses)
python -c "from nougat.utils.checkpoint import get_checkpoint; print(get_checkpoint(model_tag='0.1.0-small'))"
