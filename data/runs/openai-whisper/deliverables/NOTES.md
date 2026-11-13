# Whisper setup notes
README path (pip install + apt install ffmpeg) basically worked; nothing broke.
Changes / extra steps:
- Created a uv venv at /work/venv (Ubuntu 24.04 system Python is PEP 668 "externally managed"; plain `pip install` is refused). Python 3.12 worked fine although the README lists 3.8-3.11.
- Installed CPU-only torch from download.pytorch.org/whl/cpu first, to avoid pulling multi-GB CUDA wheels on a CPU-only machine.
- Installed whisper from the local clone (`uv pip install /work/whisper`), equivalent to the README's git install.
- Pre-downloaded tiny.en into ~/.cache/whisper in setup.sh.
Verified: `whisper tests/jfk.flac --model tiny.en --device cpu --fp16 False --output_format all` writes jfk.txt/srt/json with "ask not what your country can do for you".
