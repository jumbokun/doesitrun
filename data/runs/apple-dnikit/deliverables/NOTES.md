# dnikit setup notes

README says `pip install dnikit`; we instead install the core package from the repo
source (`/work/dnikit/src/dnikit`) into a uv venv at /work/venv (CPU only, no models needed).

What broke / what I changed:
- **Python version**: package classifiers only go up to 3.10 (system is 3.12), so the venv
  uses a uv-managed Python 3.10. Core install (annoy, numpy 2.2, scikit-learn 1.7) worked fine.
- **pytest config**: the repo's `pytest.ini` addopts force `--mypy --flake8 --cov ... --cov-fail-under 80`,
  so plain `pytest src/dnikit/tests/test_duplicates.py` errors out (unknown args without the dev
  plugins, and the 80% coverage gate would fail any single-file run anyway). setup.sh removes those
  dev-only lint/coverage options from pytest.ini (tests themselves are untouched); pytest is installed separately.
- Duplicates (Percentile(98)), DimensionReduction PCA, and Familiarity all work unpatched; the
  duplicates + dimension-reduction tests pass (2 UMAP/PaCMAP tests skip, as those extras aren't installed).
