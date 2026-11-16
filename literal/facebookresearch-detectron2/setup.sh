#!/usr/bin/env bash
# literal: facebookresearch/detectron2 @ 247691a1c292654867deb35cabb27f18d75a1363
# readme: README.md (L29 -> INSTALL.md)
set -e  # glue strict mode
# skip INSTALL.md:L19 git clone (the harness clones)
pip install torch torchvision  # prereq INSTALL.md:L5 "PyTorch ≥ 1.8 and [torchvision]"
pip install opencv-python  # prereq INSTALL.md:L7 "OpenCV is optional but needed by demo"
cd /work  # glue INSTALL.md:L20 installs from a local clone next to the working directory
python -m pip install -e detectron2  # INSTALL.md:L20
