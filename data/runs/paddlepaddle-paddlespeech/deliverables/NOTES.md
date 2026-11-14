# PaddleSpeech CPU setup notes

What broke when following the README (`pip install paddlepaddle -i https://mirror.baidu.com/pypi/simple`, `pip install pytest-runner`, `pip install .`):

- `mirror.baidu.com/pypi/simple` returns 403 -> used PyPI (paddlepaddle 3.3.1 CPU).
- On the system Python 3.12, `pip install .` fails: webrtcvad needs Python.h, and onnxoptimizer
  (paddlenlp -> paddle2onnx) has no wheel and needs cmake. Switched to uv-managed Python 3.10.
- paddle imports `setuptools` and paddlenlp imports `pip`, neither present in a bare uv venv -> `uv venv --seed` + install setuptools (<80, keeps pkg_resources for pyworld/webrtcvad).
- The resolver picks paddlenlp 2.8.1, which breaks against current transitive deps at import time (TTS path):
  `huggingface_hub` (repo_type_and_id_from_hf_id removed) -> pinned `<0.26`;
  `aistudio_sdk.hub.download` missing -> pinned `aistudio-sdk<0.3`;
  `datasets` 4.x needs newer huggingface_hub -> pinned `datasets<3`.
  Pins are in /work/constraints.txt.
- Harmless warning: opencv's cv2 built against numpy 1.x prints an ABI RuntimeError line; ASR/TTS unaffected.
- Models are downloaded on first CLI run; setup.sh runs both commands once to warm ~/.paddlespeech.

Result: `paddlespeech asr --lang zh --input zh.wav` -> 我认为跑步最重要的就是给我带来了身体健康;
`paddlespeech tts ... --output output.wav` -> 24 kHz mono wav, ~3.6 s.
