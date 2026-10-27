# Qwen cli_demo on CPU — notes

What broke when following the README:
- `requirements.txt` does not list PyTorch (the README only says "pytorch 1.12+"), so torch had to be installed separately. I installed the CPU wheel `torch==2.2.2` from the PyTorch CPU index.
- `Qwen/Qwen-1_8B-Chat` can no longer be downloaded from Hugging Face: the API returns 401 "Repository Not Found" when no token is used. The rest of the Qwen org (e.g. Qwen-1_8B, Qwen-7B-Chat) is still there.

What I changed:
- Created a Python 3.10 venv with uv at /work/venv. Installed CPU torch 2.2.2, then `requirements.txt` (which resolves to transformers 4.37.x, inside the <4.38 pin), plus `numpy<2` so it works with torch 2.2.
- Downloaded the official Qwen-1_8B-Chat weights and remote code from ModelScope (`qwen/Qwen-1_8B-Chat`, commit 8ccdac8) using git-lfs, into `/work/Qwen/Qwen/Qwen-1_8B-Chat`. setup.sh checks the sha256 of both weight files. When the command runs from /work/Qwen, transformers treats `-c Qwen/Qwen-1_8B-Chat` as this local directory, so the command works exactly as given.
- env.sh activates the venv, sets HF_HUB_OFFLINE=1 and TRANSFORMERS_OFFLINE=1, and cd's to /work/Qwen.
- No changes to the repository code.

Verified: `printf 'What is the capital of France?\n:q\n' | python cli_demo.py -c Qwen/Qwen-1_8B-Chat --cpu-only` replies "The capital of France is Paris." and exits with code 0 (about 15 s on 4 CPUs).
