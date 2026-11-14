# Qwen3-TTS on CPU — notes

README path: `conda create ... python=3.12`, `pip install -e .`, optional flash-attn, then load the model with `device_map="cuda:0"`, bf16 and flash_attention_2.

What I changed:
- There's no conda in the image, so I made a Python 3.12 venv with `uv venv` at /work/venv.
- I installed CPU-only torch/torchaudio from the PyTorch CPU index (torch 2.15.0+cpu, torchaudio 2.11.1+cpu) before `pip install -e .`. Otherwise you get the large CUDA builds by default, which aren't needed here.
- I installed system `sox`/`libsndfile1`/`ffmpeg` with apt, as a precaution for the `sox`/soundfile Python deps. The README doesn't mention them.
- I skipped flash-attn (GPU only) and loaded with `device_map='cpu'`, `dtype=torch.float32`, default attention.
- I pre-downloaded `Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice` into HF_HOME=/work/hf_cache (set in env.sh).

I didn't need any code patches. Test result: on CPU, "Hello, this is a short test..." with speaker Ryan gave a 4.4 s, 24 kHz wav in about 28 s. Whisper-tiny transcribed it back correctly.
