# garak setup notes

README path: conda env + `pip install -e .`. Used a uv venv (Python 3.12) instead; no conda in the image.

What broke and what I changed:
1. **Huge CUDA torch.** A plain install pulls CUDA torch, which isn't needed here (no GPU). I install `torch` from the PyTorch CPU index first, then run `pip install -e .`.
2. **libmagic.** The `python-magic` dependency needs the system package `libmagic1`, so setup.sh installs it with apt.
3. **gpt2 download failed.** Unauthenticated `snapshot_download('gpt2')` hit a 404 on the Xet `xet-read-token` endpoint. Setting `HF_HUB_DISABLE_XET=1` switches to plain HTTP, and that works. The model is pre-downloaded into `HF_HOME=/work/hf_cache` (also set in env.sh).
4. **README gpt2 DAN example produced no text.** The DAN 11.0 prompt is 1057 gpt2 tokens, but gpt2's context window is 1024. The pipeline cut the prompt to 1024 tokens and then tried to add 150 more, which fails with "index out of range in self". garak logs the error and records `None` outputs, so the detectors SKIP. Fix in `garak/generators/huggingface.py` (`Pipeline._call_model`): pass `max_new_tokens`, `handle_long_generation="hole"` (cuts tokens from the start of the prompt so there is room to generate) and, for deprefixed non-chat models, `return_full_text=False`. After this, gpt2 generates text and the detectors score it.

setup.sh pins garak commit 8927792 and applies the patch inline.
