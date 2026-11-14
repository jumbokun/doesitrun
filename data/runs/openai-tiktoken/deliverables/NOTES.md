# tiktoken setup notes
- The README only covers `pip install tiktoken` from PyPI. Installing from the clone (`pip install .`) means building
  the Rust extension (setuptools-rust + PyO3), and the base image has no Rust toolchain.
- Cargo.toml uses `edition = "2024"`, so it needs rustc >= 1.85. Ubuntu 24.04's apt rustc is older, so I installed
  stable Rust with rustup into /work/.cargo (this matches what pyproject's cibuildwheel config does).
- I made a uv venv at /work/venv and ran `pip install .` from /work/tiktoken. No code patches or version pins were needed.
- I set TIKTOKEN_CACHE_DIR=/work/tiktoken_cache in env.sh, and setup.sh downloads all the vocab files ahead of time.
  Without that, they download on first use.
- Checked: the README snippet works, gpt2/cl100k_base/o200k_base all work, and the repo's tests pass (33 passed).
