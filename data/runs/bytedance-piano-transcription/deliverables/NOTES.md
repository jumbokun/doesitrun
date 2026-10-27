# piano_transcription — setup notes
Following the README (`pip install piano_transcription_inference` + snippet with device='cpu') failed:
- `audioread` not installed: current librosa no longer depends on it, but piano_transcription_inference imports it -> installed `audioread`.
- `load_audio` uses `librosa.core.audio.util.buf_to_float` and positional `resample` args, removed in librosa >=0.10 -> pinned `librosa==0.9.2` (works with Python 3.12 / numpy 2).
- ffmpeg (audioread backend for mp3) and wget (used to auto-download the checkpoint) are not in the base image -> apt-installed.
- Installed CPU-only torch from the PyTorch CPU index (no GPU); Python 3.12 used instead of 3.7.
- setup.sh pre-downloads the checkpoint from Zenodo to ~/piano_transcription_inference_data/ (same path the package auto-downloads to).
Result: resources/cut_liszt.mp3 -> cut_liszt.mid with 508 notes on CPU (~2 min incl. download).
