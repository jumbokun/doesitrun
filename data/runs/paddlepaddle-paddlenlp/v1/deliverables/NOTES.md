# PaddleNLP CPU setup notes

Followed README: `pip install --upgrade paddlenlp==3.0.0b4` + CPU paddlepaddle (>=3.0.0rc1, used 3.0.0 from the Paddle CPU index), then ran the Qwen/Qwen2-0.5B quick-start with float32.

What broke:
- `import paddle` failed: `No module named 'setuptools'` (uv venvs are bare; paddle imports setuptools).
- `import paddlenlp` failed: `No module named 'pip'` (paddlenlp/utils/import_utils.py does `import pip`).
- `ImportError: cannot import name 'download' from 'aistudio_sdk.hub'`: paddlenlp 3.0.0b4 only requires aistudio-sdk>=0.1.3; current 0.3.x removed that API.

What I changed:
- Python 3.10 venv created with `uv venv --seed` (pip+setuptools), plus setuptools installed.
- Installed paddlenlp 3.0.0b4 with `uv pip install --exclude-newer 2025-03-20` so all deps resolve to versions from the b4 release time (aistudio-sdk 0.2.6, datasets 3.4.1, ...).
- PaddlePaddle 3.0.0 CPU from https://www.paddlepaddle.org.cn/packages/stable/cpu/.
- Model cached under PPNLP_HOME=/work/.paddlenlp (set in env.sh), pre-downloaded by setup.sh.
- Used dtype float32 on CPU (README comment says so). The script uses max_length=128 per the task (README uses max_new_tokens=128).

Result: output `['我是一个AI语言模型，我可以回答各种问题，...请问您有什么需要了解的吗？']`, matching the README.
