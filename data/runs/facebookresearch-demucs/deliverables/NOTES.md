# demucs setup notes
- README path (`pip install -e .` / conda env) doesn't work on stock Ubuntu 24.04: Python 3.12 has no
  wheels for `torchaudio<2.1` (pinned in requirements). Used a uv venv with Python 3.11, and installed CPU torch 2.0.1 / torchaudio 2.0.2
  from the PyTorch CPU index.
- Pinned `numpy<2` (torch 2.0 is built against numpy 1.x).
- torch 2.0 imports `pkg_resources`; fresh venvs don't include setuptools -> installed `setuptools<81`.
- Installed system `ffmpeg` (demucs uses it to decode mp3) and `libsndfile1` + `soundfile` (backend that torchaudio uses to write wavs).
- Running python from /work picks up /work/demucs as a namespace package and shadows the real package, so the weight pre-download runs from /tmp.
- htdemucs weights are pre-downloaded into ~/.cache/torch/hub/checkpoints during setup.
