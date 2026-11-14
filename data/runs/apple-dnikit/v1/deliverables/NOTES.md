# dnikit setup notes
- README only says `pip install dnikit`; installed from repo source instead: `uv pip install -e src/dnikit[test]` in a Python 3.10 venv (classifiers stop at 3.10).
- Repo `pytest.ini` adds `--mypy --flake8 --cov`, so the test extras are needed. pytest-flake8 1.3.0 breaks on pytest >= 8 (`path` hookimpl arg removed), so pinned `pytest<8`.
- `pytest.ini` also sets `--cov-fail-under 80` over all of src, which fails when running only test_duplicates.py; env.sh sets `PYTEST_ADDOPTS=--cov-fail-under=0`.
- Result: test_duplicates.py passes (6 tests incl. flake8+mypy); Duplicates finds planted clusters in synthetic StubProducer data.
