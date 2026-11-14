# coreai-torch on Linux CPU

- The README's `uv sync` / `pip install -e .` path works on Linux x86_64: coreai-core 1.0.0b3 ships manylinux_2_34 wheels, and its runtime runs the quickstart on CPU.
- What I changed: I used `uv venv --python 3.12` plus `uv pip install -e .` instead of `uv sync`, so that torch comes from the PyTorch CPU wheel index. Otherwise the default PyPI torch pulls in the large CUDA wheels.
- torch is pinned to 2.13.0, the version the repo's test extra pins. With the latest torch (2.15) coreai-torch warns that it "has only been validated with torch<=2.13.0".
  The warning still shows with 2.13.0+cpu because the version check treats the `+cpu` suffix as newer. It is harmless.
- The quickstart notebook uses top-level `await`. As a plain script, the async function is run with `asyncio.run(...)`.
- Result: the MLP from the quickstart, saved to .aimodel and run via `main`, matches PyTorch (max abs diff ~3e-8).
