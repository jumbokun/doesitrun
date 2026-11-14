# Megatron-LM preprocess_data.py on CPU — notes

Commit: 05c4a8ba04e2d3422f56ffdda7ff2059da431e18. Python 3.12 venv at /work/venv.

## What broke following the README (`git clone ...; uv pip install -e .`)
1. **torch never got installed.** `pyproject.toml` has `[tool.uv] override-dependencies`
   with `torch; sys_platform == 'never'` and the same for triton and torchvision (meant for NGC/PyTorch base images). So
   running `uv pip install ...` from inside the checkout quietly skips torch and triton, even when you
   ask for them by name. uv says "Checked 1 package" and installs nothing. Fix: install torch and triton with
   `uv pip install --no-config` from outside the repo dir.
2. **CPU-only box:** I installed the CPU torch wheel (`torch==2.15.0+cpu`) from download.pytorch.org/whl/cpu.
3. **`triton` is required even on CPU:** `megatron/core/__init__.py` pulls in
   `transformer/moe/ops/paged_stash.py`, which does `import triton` unconditionally. The CPU torch
   wheel doesn't bring triton along, so I installed `triton==3.9.0` from PyPI.
4. **`transformers` is needed** for `--tokenizer-type HuggingFaceTokenizer`. It's only in the
   `training` extra, and the README doesn't mention it. I installed `transformers==5.23.0`.
5. Undocumented step: download the GPT-2 tokenizer files (config.json, tokenizer.json,
   tokenizer_config.json, vocab.json, merges.txt) from huggingface.co/openai-community/gpt2 into /work/gpt2.

I didn't patch any code. Warnings about Transformer Engine/Apex/absl being missing are harmless.
