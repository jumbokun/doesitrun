# evalscope on CPU — notes

Followed README "Method 2: Evaluate a Local Model" (`pip install evalscope` route, done as an editable source install in a uv Python 3.11 venv at /work/venv, commit 59bb367).

What broke and the fixes:
1. **torch missing**: core requirements don't include torch, so local-model eval fails with `ImportError: torch not found ... llm_ckpt`. The CLI still exits 0 when this happens. Fix: install the CPU torch wheel from download.pytorch.org/whl/cpu.
2. **accelerate missing**: transformers' `from_pretrained` with `device_map` needs `accelerate`. Fix: `pip install accelerate`.
3. **transformers 5.x incompatible**: the resolver picks transformers 5.23, and `apply_chat_template` then fails with `'ChatMessageUser' object has no attribute 'items'`, because evalscope passes pydantic message objects instead of dicts. Fix: pin `transformers<5` (4.57.6 was installed).
4. The image ships Python 3.12, which meets the README's ">=3.11"; I used a uv venv with 3.11 anyway. This was my choice, not a requirement, so it is not listed in REPORT.json.

Result: `evalscope eval --model Qwen/Qwen2.5-0.5B-Instruct --datasets gsm8k --limit 5 --work-dir DIR` downloads the model and dataset from ModelScope and writes `DIR/<ts>/reports/Qwen2.5-0.5B-Instruct/gsm8k.json` (5 samples, accuracy 40%). It takes about 2 minutes on CPU.
