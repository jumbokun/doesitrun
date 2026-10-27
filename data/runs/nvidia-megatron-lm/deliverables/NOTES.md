# Megatron-LM preprocess_data.py on CPU — notes

Tested at commit 19895dafba387fe4807d433809fbdeeb801bf7f6, Python 3.12, uv venv at /work/venv.

README path: `uv pip install -e .` installs fine, but `tools/preprocess_data.py` did not work as written:

1. **Torch for CPU**: the README doesn't cover CPU-only setups. I installed torch from the PyTorch CPU index
   (`--index-url https://download.pytorch.org/whl/cpu`) before running `uv pip install -e .`.
2. **Missing `triton`**: `import megatron.core` fails with `ModuleNotFoundError: triton`, because
   `megatron/core/transformer/moe/ops/paged_stash.py` imports it unconditionally and the CPU torch wheel
   doesn't pull it in. Fixed with `uv pip install triton`; it imports fine without a GPU.
3. **Missing `transformers`**: the HuggingFaceTokenizer needs it, but it's only in the `training`/`mlm` extras,
   not the base install.
4. **transformers 5.x breaks `--append-eod` with GPT-2**: under transformers 5.x (uv.lock pins 5.19.0),
   `AutoTokenizer.from_pretrained` on the GPT-2 dir (whose tokenizer_config.json only has `model_max_length`)
   returns `eos_token=None`. So `tokenizer.eod` is None, and the worker crashes in `add_document`
   (`int() ... not 'NoneType'`). The main process then **hangs forever** waiting on the dead worker.
   Fixed by pinning `transformers<5` (4.57.x), which gives eos `<|endoftext|>` = 50256.
5. I downloaded the GPT-2 tokenizer files to /work/gpt2 with curl. No token was needed.

There are no code patches. env.sh activates the venv and changes into /work/Megatron-LM, so `python tools/preprocess_data.py` resolves.
I verified that 20 documents load through IndexedDataset, each ending in 50256, and decode back to the exact original text.
