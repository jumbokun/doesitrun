# Kats setup notes

The README's `pip install kats` does not work as written:

1. **fbprophet build fails.** `kats` 0.2.0 on PyPI (and `test_requirements.txt`) pins `fbprophet==0.7.1`
   and `pystan==2.19.1.1`, which do not build (no `pkg_resources` in the build env, plus obsolete pystan).
   The repo code imports the modern `prophet` package, so I install Kats from the clone with
   `MINIMAL_KATS=1` and add `prophet==1.3.0` (it ships a prebuilt cmdstan).
2. **Python version.** The code uses 3.10+ features (`typing.TypeAlias`, `Literal[...] | Literal[...]`),
   and the `numpy<1.22` pin has no wheels past 3.10, so it has to be Python 3.10. The CI file still
   tests 3.8/3.9.
3. **statsmodels pin.** `statsmodels==0.12.2` has no 3.10 wheel. Built from source, it imports
   `scipy.signal.signaltools._centered`, which was removed in scipy 1.8, so it clashes with the repo's
   own `scipy>=1.10` pin. I override it to `statsmodels==0.13.5`.
4. **pkg_resources.** pandas 1.3.5 needs `pkg_resources` at runtime, so I install `setuptools<70`.
5. **pyre-extensions.** `kats.detectors.prophet_detector` imports `pyre_extensions`, which is not
   declared anywhere, so I install it.

No source files were patched. The venv is at /work/venv, and env.sh activates it and cds to /work/Kats.
