#!/usr/bin/env bash
# Reproduce the Kats environment (CPU-only) from scratch.
set -euxo pipefail
cd /work
[ -d /work/Kats/.git ] || git clone https://github.com/facebookresearch/Kats /work/Kats

# Kats code uses Python 3.10+ syntax (typing.TypeAlias, X | Y unions); requirements pin numpy<1.22,
# which has no wheels past 3.10 -> Python 3.10 is the only workable version.
uv python install 3.10
rm -rf /work/venv
uv venv -p 3.10 /work/venv
export VIRTUAL_ENV=/work/venv PATH=/work/venv/bin:$PATH

# statsmodels==0.12.2 (pinned) has no py3.10 wheel and imports scipy internals removed in scipy>=1.8,
# conflicting with the scipy>=1.10 pin. Override to 0.13.5 (py3.10 wheels, works with scipy 1.11/numpy 1.21).
cat > /work/overrides.txt <<'OV'
statsmodels==0.13.5
OV

# Optional deps (test_requirements.txt) pin fbprophet==0.7.1/pystan 2.19 which do not build;
# the code actually imports the modern `prophet` package, so install minimal Kats + prophet.
# pandas 1.3.5 plotting imports pkg_resources -> needs setuptools<70 in the venv.
# kats.detectors.prophet_detector imports pyre_extensions, which is not declared anywhere.
cd /work/Kats
MINIMAL_KATS=1 uv pip install --overrides /work/overrides.txt -e . \
    "prophet==1.3.0" "scipy==1.11.4" "numpy==1.21.6" "pandas==1.3.5" "setuptools<70" pyre-extensions

python -c "import kats, prophet, statsmodels; print('kats ok', statsmodels.__version__)"
