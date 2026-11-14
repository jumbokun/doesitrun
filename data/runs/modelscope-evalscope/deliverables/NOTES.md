# evalscope Method 2 on CPU — notes

I followed the README: `pip install evalscope` (1.15.0) on Python 3.12, then ran `evalscope eval --model Qwen/Qwen2.5-0.5B-Instruct --datasets gsm8k arc --limit 5`.

What broke and how I fixed it:
1. **`torch` is not installed.** The command failed with `ImportError: torch not found ... llm_ckpt`. The base requirements leave torch out. Fix: install the CPU build from the PyTorch CPU index.
2. **`accelerate` is not installed.** `from_pretrained` uses `device_map` and fails with "requires `accelerate`". Fix: `pip install accelerate`.
3. **transformers 5.x does not work.** The resolver pulls in transformers 5.23, and its `apply_chat_template` calls `.items()` on each message. evalscope passes pydantic `ChatMessageUser` objects, so it fails with `AttributeError: 'ChatMessageUser' object has no attribute 'items'`. The same code is still on GitHub main. Fix: pin `transformers<5` (4.57.6 was installed).

After these fixes the run finishes on 4 CPU cores in about 7 minutes. Results: GSM8K 40% on 5 samples, ARC 60% on 10 (5 Easy and 5 Challenge). Reports and reviews go to `<work-dir>/<timestamp>/{reports,reviews}`.

`setup.sh` creates the venv at /work/venv. It also downloads the model and runs a warm-up eval with `--limit 1` so both datasets are cached in `~/.cache/modelscope`.
