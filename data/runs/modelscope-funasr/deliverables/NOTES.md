# FunASR SenseVoiceSmall CPU example — notes

**Result:** the README path worked as written. Python 3.12, `pip install torch torchaudio`, `pip install -e ./`, then the
SenseVoiceSmall + fsmn-vad + cam++ example on `runtime/funasr_api/asr_example.wav` printed
`[0.6s] Speaker 0: 欢迎大家来体验达摩院推出的语音识别模型`.

None of these changes were needed to make it work:
- Installed torch/torchaudio from the PyTorch CPU wheel index (pinned to torch 2.14.1 / torchaudio 2.11.0, the versions
  that got resolved) so the download is smaller and repeat installs get the same versions. Plain PyPI wheels should work too.
- Installed ffmpeg with apt only to silence the "ffmpeg is not installed" notice. torchaudio reads the wav without it.
- Used the local wav instead of the README's URL, as the task requires.
- Expected log line: "punc_model is missing, falling back to vad_segment mode". Segments are VAD segments with speaker ids.

Files: `setup.sh` (clone, venv at /work/venv, install, model pre-download via /work/test/demo.py), `env.sh` (activates venv).
