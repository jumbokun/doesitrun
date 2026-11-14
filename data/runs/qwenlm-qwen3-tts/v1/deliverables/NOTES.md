# Qwen3-TTS on CPU — notes

The README path (fresh Python 3.12 env, `pip install -e .`, `Qwen3TTSModel.from_pretrained(...)`) mostly works. These were the gaps:

- **No conda in the image.** I used `uv venv --python 3.12` (/work/venv) instead of `conda create`.
- **torch isn't declared.** pyproject has no `torch` entry; it only comes in through `torchaudio`, and the default wheel pulls the CUDA build. I installed `torch==2.8.0`/`torchaudio==2.8.0` from the PyTorch CPU index first, then installed the package.
- **System packages.** I added `sox` and `libsndfile1` (plus ffmpeg) through apt. The python `sox` package shells out to the sox binary, and soundfile needs libsndfile.
- **CPU usage.** The README example uses `cuda:0`, bf16 and flash_attention_2. I used `device_map='cpu'`, `dtype=torch.float32` and left out `attn_implementation`. It falls back to the manual attention path and prints a warning about flash-attn.
- **Weights.** I pre-downloaded `Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice` and `Qwen/Qwen3-TTS-Tokenizer-12Hz` with `hf download` into HF_HOME=/work/hf_cache. env.sh exports this path.

Result: a 4.7 s, 24 kHz wav from English text with speaker Ryan, in about 38 s on 4 CPU cores. I didn't patch any code.
