#!/usr/bin/env bash
# literal: PaddlePaddle/PaddleClas @ 202ac79a99aa368f2c95cb1871bbc11574f685da
# readme: README_en.md (README.md is a stub pointing to README_ch.md), docs/en/inference_deployment/whl_deploy_en.md
set -e  # glue strict mode
# choice: README_en.md:L100 sends the reader to the whl doc; its second option (local build, whl_deploy_en.md:L37) because the test runs the clone; PyPI is listed first
cd /work/PaddleClas  # glue whl_deploy_en.md:L37 implies being inside the repo
pip install -v -e .  # docs/en/inference_deployment/whl_deploy_en.md:L37
# mismatch README_en.md:L54-L55 link to docs/en/installation/install_paddle_en.md and install_paddleclas_en.md, which do not exist (404); no step installs paddlepaddle, which the test needs
