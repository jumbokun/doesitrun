# chalice quickstart (offline)
Following the README worked: `pip install` chalice (here from the /work/chalice clone instead of PyPI),
`chalice new-project helloworld`, `chalice local --port 8000` -> GET / returns {"hello":"world"}.
No AWS credentials needed for `chalice local`.
Minor deviation: README quickstart shows Python 3.10; the system Python 3.12 (supported, python_requires>=3.10) was used in a venv at /work/.venv.
