# python-fire setup notes
- README's from-source install says `python setup.py install`, but the repo no longer has a setup.py (it's pyproject.toml only), so that command fails with "No such file".
- What I did instead: created a venv at /work/venv with uv and ran `uv pip install /work/python-fire` (this is the same as `pip install .`). It pulls in termcolor.
- `env.sh` activates the venv.
- The README examples (hello.py, calculator.py) and examples/cipher and examples/diff all run without any code changes. Run the examples from the repo root, e.g. `python examples/cipher/cipher.py rot13 hello`.
