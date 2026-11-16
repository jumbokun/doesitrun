#!/usr/bin/env bash
# literal: facebookresearch/pytorch3d @ 3eac7c62fed39a09768cd08119c5e1bf4daef559
# readme: README.md + INSTALL.md (README.md:L147 sends the reader to INSTALL.md)
set -e  # glue strict mode
# choice: INSTALL.md gives conda for the runtime dependencies (L19-L25) and "install from a local clone" (L126-L130) for the library; the test runs from the clone
# choice: INSTALL.md:L23 names pytorch-cuda=11.6 (no CPU variant is given); run as written, it needs no GPU to install
curl -fsSL https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -o /tmp/miniforge.sh  # prereq INSTALL.md:L21 "conda create"
bash /tmp/miniforge.sh -b -p /opt/conda  # prereq INSTALL.md:L21 "conda create"
source /opt/conda/etc/profile.d/conda.sh  # prereq INSTALL.md:L21 "conda create"
conda config --set always_yes true  # prereq INSTALL.md:L21 "conda create"
conda create -n pytorch3d python=3.9  # INSTALL.md:L21
conda activate pytorch3d  # INSTALL.md:L22
conda install pytorch=1.13.0 torchvision pytorch-cuda=11.6 -c pytorch -c nvidia  # INSTALL.md:L23
conda install -c iopath iopath  # INSTALL.md:L24
# skip INSTALL.md:L128 git clone (harness clones)
cd /work/pytorch3d  # glue INSTALL.md:L129 implies being inside the repo
pip install -e .  # INSTALL.md:L129
