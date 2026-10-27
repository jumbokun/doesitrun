# VibeVoice-Realtime-0.5B on CPU — notes

README path (docs/vibevoice-realtime-0.5b.md): NVIDIA docker + `pip install -e .[streamingtts]` + run the demo script.

What broke:
- `pip install -e .[streamingtts]` leaves torch unpinned, so it pulls the latest torch (2.14). With it,
  `demo/realtime_model_inference_from_file.py` fails while loading the voice preset
  (`torch.load(..., weights_only=True)` inside `safe_globals`):
  `UnpicklingError: Can only SETITEMS for dict ... but got BaseModelOutputWithPast`.

What I changed:
- Python venv made with uv (Python 3.12) instead of the NVIDIA container; no GPU / flash-attn.
- Installed CPU-only torch==2.8.0 / torchaudio==2.8.0 from the PyTorch CPU index (also avoids the multi-GB CUDA wheels).
  With 2.8.0 the voice preset loads fine. No code changes.
- Installed ffmpeg + libsndfile1 (audio I/O) and pre-downloaded the HF model + Qwen2.5-0.5B tokenizer into HF_HOME=/work/hf_cache.
- The "newly initialized acoustic_tokenizer.encoder" warning is harmless: the streaming model only uses the decoder.

Result: 5–6 s, non-silent 24 kHz WAV for a short English sentence, about 20 s on 4 CPU cores.
