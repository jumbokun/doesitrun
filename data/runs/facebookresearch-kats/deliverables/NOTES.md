# Kats setup notes

The README says `pip install kats`. Following it fails.

- `pip install kats` (PyPI 0.2.0) / full install from the clone pulls `fbprophet==0.7.1` + `pystan==2.19.1.1`, which don't build on a modern Python/setuptools (missing pkg_resources, pystan 2 compilation). The repo code actually imports `prophet`, not `fbprophet`. So I installed from the clone with `MINIMAL_KATS=1` and added `prophet` separately.
- Python version: `kats/compat/compat.py` uses `typing.TypeAlias`, which needs Python 3.10 or newer, but `numpy<1.22` needs Python 3.10 or older. I used **Python 3.10** (uv venv at /work/venv).
- The `statsmodels==0.12.2` pin conflicts with `scipy>=1.10`: statsmodels 0.12.2 imports `scipy.signal.signaltools._centered`, which no longer exists. It also has no cp310 wheel. I overrode it to `statsmodels==0.13.5`.
- `numba` resolved to 0.58, which needs numpy 1.22 or newer. I pinned `numba==0.56.4`.
- `prophet` 1.1.5/1.1.6 with `cmdstanpy` 1.3 fails ("CmdStan installation missing makefile"), which leads to `'Prophet' object has no attribute 'stan_backend'`. I pinned `prophet==1.1.6` and `cmdstanpy==1.2.4`.
- pandas 1.3.5 imports `pkg_resources`, so I installed `setuptools<70`.
- README snippets use `../kats/data/air_passengers.csv`. That path is wrong when you run from the repo root; use `kats/data/air_passengers.csv`.

Verified from /work/Kats: Prophet forecast returns 30 rows, CUSUM finds an increase change point at 2019-01-30 (index 29), and TsFeatures returns 40 features. TsFeatures prints some debug output (`AC[i]` lines) from repo code; this is harmless.
