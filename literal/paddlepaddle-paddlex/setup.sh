#!/usr/bin/env bash
# literal: PaddlePaddle/PaddleX @ ffb64904d23708863ff5b8da312a5cbd52a7f462
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L596 is the CPU PaddlePaddle build; L599 and L602 are GPU-only
python -m pip install paddlepaddle==3.3.0 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/  # README.md:L596
# skip README.md:L599 GPU-only alternative
# skip README.md:L602 GPU-only alternative
pip install "paddlex[base]"  # README.md:L609
