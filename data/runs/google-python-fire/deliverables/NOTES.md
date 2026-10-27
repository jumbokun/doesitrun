# python-fire setup notes

- **What broke:** The README's from-source instruction, `python setup.py install`, fails because the repo no longer has a `setup.py`. Packaging moved to `pyproject.toml`.
- **What I changed:** I ran `pip install /work/python-fire` (using `uv pip`) into a venv at `/work/.venv`. A venv is needed because Ubuntu 24.04's system Python is externally managed (PEP 668), so pip won't install into it directly. termcolor was pulled in automatically as a dependency.
- `env.sh` activates `/work/.venv`.
- **Checked:**
  - The README examples give the expected output: `Hello World!`, `Hello David!`, help text, `20`, `30`.
  - The repo examples run as CLIs, e.g. `python examples/cipher/cipher.py rot13 'Hello world!'` and `python -m examples.widget.widget whack 3` from the repo root.
- No code patches were needed.
