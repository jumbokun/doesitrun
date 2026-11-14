# demucs setup notes
README path: `pip install` of the repo (requirements_minimal.txt). Problems hit:
- `torchaudio>=0.8,<2.1` has no wheels for the system Python 3.12 -> created a uv venv with Python 3.11 (/work/venv).
- Installed CPU-only torch==2.0.1 / torchaudio==2.0.2 from the PyTorch CPU index (the README doesn't cover CPU-only installs via pip).
- torch 2.0.x is built against NumPy 1.x -> pinned `numpy<2`.
- torch 2.0.x imports `pkg_resources`, which recent setuptools (>=81) removed -> pinned `setuptools<81`.
- ffmpeg isn't in the base image, and demucs needs it to decode mp3 -> `apt-get install ffmpeg`.
- Running `python -c "import demucs"` from /work picks up the repo directory /work/demucs as a namespace package and shadows the real package, so the weights pre-download runs from /tmp.
- htdemucs weights (955717e8-8726e21a.th) get pre-downloaded into ~/.cache/torch/hub/checkpoints.
Result: `python3 -m demucs --two-stems=vocals -d cpu -o OUT test.mp3` writes OUT/htdemucs/test/{vocals,no_vocals}.wav (each 20.0 s, 44.1 kHz stereo).
