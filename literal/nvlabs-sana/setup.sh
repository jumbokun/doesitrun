#!/usr/bin/env bash
# literal: NVlabs/Sana @ 27303b8de8e3f02f5dc96acf14705a0e04fca355
# readme: README.md
set -e  # glue strict mode
# skip README.md:L146 git clone (the harness clones)
curl -fsSL https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -o /tmp/miniforge.sh  # prereq docs/installation.md:L5 "Miniconda"
bash /tmp/miniforge.sh -b -p /opt/conda  # prereq docs/installation.md:L5 "Miniconda"
source /opt/conda/etc/profile.d/conda.sh  # prereq docs/installation.md:L5 "Miniconda"
cd /work  # glue README.md:L147 runs cd Sana from the directory holding the clone
cd Sana && ./environment_setup.sh sana  # README.md:L147
# mismatch the README example uses SANA1.5_1.6B on cuda; the test runs Sana_600M_512px_diffusers on cpu, which the README never mentions
