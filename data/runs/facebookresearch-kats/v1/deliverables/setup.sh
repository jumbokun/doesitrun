#!/usr/bin/env bash
# Reproducible setup for facebookresearch/Kats (CPU only).
set -euo pipefail
cd /work
[ -d /work/Kats/.git ] || git clone https://github.com/facebookresearch/Kats /work/Kats

# Kats code uses typing.TypeAlias (py>=3.10) but pins numpy<1.22 (py<=3.10) -> Python 3.10.
rm -rf /work/venv
uv venv -p 3.10 /work/venv
. /work/venv/bin/activate

# statsmodels==0.12.2 (pinned) is incompatible with scipy>=1.10 (also pinned): override.
cat > /work/overrides.txt <<'OV'
statsmodels==0.13.5
OV
# pandas 1.3.5 needs pkg_resources (setuptools). numba>=0.57 needs numpy>=1.22; prophet 1.1.6 needs cmdstanpy<1.3 (makefile check).
cat > /work/constraints.txt <<'CS'
numba==0.56.4
prophet==1.1.6
cmdstanpy==1.2.4
CS

cd /work/Kats
# Full install pulls fbprophet==0.7.1/pystan 2 (unbuildable); kats code imports `prophet` instead.
MINIMAL_KATS=1 uv pip install --override /work/overrides.txt -c /work/constraints.txt \
    -e . prophet numba "setuptools<70"
python -c "import kats, prophet, numba, statsmodels; print('kats ok')"
