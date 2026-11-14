# Qwen cli_demo on CPU — notes

Running `pip install -r requirements.txt` and then `python cli_demo.py -c <ckpt> --cpu-only` did not work as written. Here's what broke and what I changed:

- **PyTorch isn't in requirements.txt.** The README only lists it as a prerequisite ("pytorch 1.12 and above"). I installed the CPU wheel `torch==2.4.1` from download.pytorch.org/whl/cpu into a uv venv (Python 3.12, `/work/venv`).
- **Pins:** `numpy<2` and `huggingface_hub<0.26`, as a precaution so they stay compatible with transformers <4.38 and torch 2.4.
- **Hugging Face model repo is gone.** The README links `Qwen/Qwen-1_8B-Chat` on Hugging Face, but the API now returns 401 / "Repository Not Found" without a token. I followed the README's ModelScope fallback instead: `pip install modelscope`, then `snapshot_download("qwen/Qwen-1_8B-Chat")` into `/work/models/Qwen-1_8B-Chat`. env.sh exports `QWEN_CKPT` pointing there and sets `HF_HUB_OFFLINE=1`.
- **Slow download:** the ModelScope download is about 3.5 GB and took around 50 minutes from this sandbox.
- **No code changes.** Piping "What is the capital of France?" and then ":q" into the demo answers "The capital of France is Paris." and exits with code 0.
