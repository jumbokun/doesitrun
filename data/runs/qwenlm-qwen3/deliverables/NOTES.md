# Qwen3 README Transformers snippet on CPU

- README gives no install command beyond "transformers>=4.51.0 is required". It does not mention torch at all; I installed the CPU wheel (torch 2.15.0+cpu) from the PyTorch CPU index so the CUDA build isn't downloaded.
- The snippet uses `device_map="auto"`, and that needs `accelerate`, which the README never mentions. Without it you get `ValueError: Using a device_map ... requires accelerate`. I installed it.
- I swapped the model name `Qwen/Qwen3-30B-A3B-Instruct-2507` for `Qwen/Qwen3-0.6B`, as the task asks. setup.sh pre-downloads it into the HF cache.
- `max_new_tokens=16384` works on CPU but can be slow. I tested with 200 and got coherent output about LLMs in about 16 s. Qwen3-0.6B is a hybrid thinking model, so its output begins with a `<think>` block.
- The environment is a uv venv at /work/venv (Python 3.12) with transformers 5.23.0. env.sh activates it.
