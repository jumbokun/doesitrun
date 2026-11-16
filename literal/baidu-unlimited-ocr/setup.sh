#!/usr/bin/env bash
# literal: baidu/Unlimited-OCR @ 37cf646758611a3b81f53863d1e91128a98d58b1
# readme: README.md
set -e  # glue strict mode
# choice: README.md:L77 Transformers path (the SGLang path L112+ is GPU serving)
pip install torch==2.13.0 torchvision pillow transformers==4.52.1 huggingface-hub==0.36.0 tokenizers==0.21.4 addict==2.4.0 einops==0.8.2 easydict==1.13  # README.md:L81-L82
