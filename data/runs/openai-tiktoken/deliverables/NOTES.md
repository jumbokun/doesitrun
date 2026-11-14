# tiktoken setup notes
- README only documents `pip install tiktoken` from PyPI; installing from the clone builds a Rust
  extension via setuptools-rust, which needs a Rust toolchain not present in the base image.
  Installed Rust with rustup (minimal profile), as the project's cibuildwheel config does.
- Created a uv venv (Python 3.12) at /work/venv and ran `uv pip install /work/tiktoken`.
- Vocab files are pre-downloaded into TIKTOKEN_CACHE_DIR=/work/tiktoken_cache (set in env.sh)
  so verification doesn't depend on a temp-dir cache.
- Running tests from inside the repo root shadows the installed package (no compiled `_tiktoken`
  in the source tree); run them from another directory. 33/33 tests pass.
- No code changes.
