# MegaTTS3 CPU setup notes

- README uses conda; I used `uv` with a Python 3.10 venv at /work/venv instead (conda isn't in the image).
- `pip install -r requirements.txt` failed: `openai-whisper==20240930` builds from an sdist whose setup.py
  imports `pkg_resources`, and current setuptools (>=81) no longer ships it. Fix: build constraint `setuptools<81`.
- Installed torch/torchaudio 2.6.0 from the PyTorch CPU wheel index so the multi-GB CUDA wheels aren't pulled in (CPU-only machine).
- Checkpoints: the README just says "download and put in ./checkpoints". I used `huggingface_hub.snapshot_download("ByteDance/MegaTTS3", local_dir=checkpoints)` with no token.
- Installed `ffmpeg` and `libsndfile1` via apt (the Dockerfile installs ffmpeg; it's used for pydub/librosa audio loading).
- No code changes needed. The CLI falls back to CPU by itself (you get harmless autocast warnings). It takes about 2 minutes per short sentence on 4 cores.
- I checked the output with whisper-tiny: it transcribed back to the exact input sentence.
- env.sh activates the venv, sets PYTHONPATH=/work/MegaTTS3, sets CUDA_VISIBLE_DEVICES="", and cd's into the repo (the CLI uses relative ./checkpoints paths).
