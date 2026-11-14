# PaddleNLP quick-start on CPU

Followed README: install paddlepaddle (CPU, 3.0.0 from the paddle CPU index) + `pip install paddlenlp==3.0.0b4`, then ran the Qwen/Qwen2-0.5B generation snippet with dtype float32.

What broke / what I changed:
- Plain install pulls today's latest transitive deps; `import paddlenlp` then fails:
  `cannot import name 'download' from 'aistudio_sdk.hub'` (aistudio-sdk API changed; also datasets 5.x, protobuf 7).
  Fix: resolve deps with `uv pip install --exclude-newer 2025-03-20` (paddlenlp 3.0.0b4 release date), with paddlepaddle allowed up to 2025-04-30 for 3.0.0.
- paddle imports `setuptools`, paddlenlp imports `pip`; neither is declared as a dependency, and a bare uv venv has neither. Created venv with `--seed` + installed setuptools/pip.
- Used Python 3.10 (via uv) to stay within the versions paddlenlp 3.0.0b4 was tested on (the system has 3.12).
- CPU: float32 instead of float16 (README comment already says so).
- Model downloads automatically from the PaddleNLP community bucket into ~/.paddlenlp; setup.sh pre-fetches it.

Result: generation prints e.g. "我是一个AI语言模型，我可以回答各种问题……". A harmless warning says lm_head.weight is "newly initialized" (Qwen2-0.5B ties embeddings); the output is coherent anyway.
Frozen versions that worked: /work/requirements.lock.
