# Megatron-LM preprocess_data.py on CPU

README path: `git clone ...; cd Megatron-LM; uv pip install -e .`

What broke:
1. `uv pip install -e .` reports success, but **torch is never installed**. `pyproject.toml` `[tool.uv] override-dependencies`
   contains `torch; sys_platform == 'never'` (and triton), because it assumes an NGC PyTorch container. Run from the
   repo dir, even `uv pip install torch` silently does nothing ("Checked 1 package").
   Fix: install the CPU torch wheel with `uv pip install --no-config --index-url https://download.pytorch.org/whl/cpu torch`.
2. `import megatron.core` unconditionally imports `triton` (via moe/ops/paged_stash.py), so the import fails without it.
   Fix: `uv pip install --no-config triton` (the PyPI wheel imports fine on CPU).
3. preprocess_data.py with HuggingFaceTokenizer needs `transformers` (it's only in the `training` extra, which the README doesn't mention).
   I installed transformers, tokenizers, sentencepiece, tiktoken and nltk directly instead of pulling the whole heavy extra.
4. GPT-2 tokenizer files come from huggingface.co/openai-community/gpt2 and are saved to /work/gpt2.

No code patches. env.sh activates /work/Megatron-LM/.venv and adds the repo to PYTHONPATH.
Checked: 20 docs written, each decodes back to its input text and ends with EOD (50256).
