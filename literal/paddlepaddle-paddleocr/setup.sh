#!/usr/bin/env bash
# literal: PaddlePaddle/PaddleOCR @ dab3fe35379033fdcb2d0e9572fac0b36c9a9ebf
# readme: README.md -> docs/version3.x/installation.en.md -> docs/version3.x/paddlepaddle_installation.en.md
set -e  # glue strict mode
source /work/.venv/bin/activate  # glue the harness venv
# choice: installation.en.md:L19 default capabilities from PyPI (first alternative); then the CPU PaddlePaddle wheel
python -m pip install paddleocr  # docs/version3.x/installation.en.md:L19
python -m pip install paddlepaddle==3.2.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/  # docs/version3.x/paddlepaddle_installation.en.md:L56
