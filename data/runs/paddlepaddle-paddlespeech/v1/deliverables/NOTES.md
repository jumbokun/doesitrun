# PaddleSpeech on CPU – notes

README path: `pip install paddlepaddle -i https://mirror.baidu.com/pypi/simple`, `pip install pytest-runner`, `pip install .`

What broke / what I changed:
- `mirror.baidu.com` returns HTTP 403 -> installed `paddlepaddle==3.3.1` (CPU) from PyPI.
- Python 3.12 (system): `webrtcvad` needs Python.h, and `onnxoptimizer==0.3.13` (pulled in via paddlenlp -> paddle2onnx) has no cp312 wheel and needs cmake to build -> used a uv-managed Python 3.10 venv.
- The uv venv has no setuptools/pip; `import paddle` needs setuptools and `paddlenlp` does `import pip` -> venv created with `--seed` / pip+setuptools installed.
- paddlenlp 2.8.1 is incompatible with current deps (TTS import fails): pinned `huggingface_hub<0.26`
  (missing `repo_type_and_id_from_hf_id`), `aistudio-sdk==0.2.6` (missing `aistudio_sdk.hub.download`),
  `datasets<3` (newer needs `huggingface_hub.errors.BucketNotFoundError`).
- ASR auto-pip-installs `paddlespeech_ctcdecoders` at runtime; installed it up front.
- Models (~5 GB, `~/.paddlespeech`, `~/.paddlenlp`) are pre-fetched in setup.sh by running both commands once.

Result: ASR prints `我认为跑步最重要的就是给我带来了身体健康`; TTS writes a 3.56 s 24 kHz mono PCM16 wav.
