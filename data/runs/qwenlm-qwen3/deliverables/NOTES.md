# Qwen3 README Transformers snippet on CPU

- The README has no install instructions. It only says `transformers>=4.51.0` is required.
- The snippet uses `device_map="auto"`, which raises `ValueError ... requires accelerate` when only torch and transformers are installed. Fix: `pip install accelerate`.
- No GPU: installed the CPU-only torch wheel from download.pytorch.org/whl/cpu.
- Changed the model name to Qwen/Qwen3-0.6B, as the task asked. It is pre-downloaded into HF_HOME=/work/hf_cache, which env.sh exports.
- Result: the snippet runs on CPU unchanged otherwise. It got transformers 5.x and Python 3.12 in a uv venv at /work/venv. Qwen3-0.6B is a thinking model, so the output starts with a `<think>` block. That is expected.
- max_new_tokens=16384 is very slow on CPU. I used 256 for testing.
