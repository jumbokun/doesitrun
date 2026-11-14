# FunClip CLI demo on CPU: notes

Setup follows the Linux CPU recipe in docs/installation.md: Python 3.12 venv, torch/torchaudio 2.10.0+cpu, then `requirements.txt`. Pip resolved everything and `pip check` was clean.

What broke or was missing when following README section C:
1. **ffmpeg isn't installed by default.** The README never says to install it (only docs/installation.md mentions it), so setup.sh runs `apt-get install ffmpeg`.
2. **The example video download fails with `wget`.** It gets a 403 from the HF xet CDN after the redirect. `curl -L` on the same URL works.
3. **The README's `--dest_text` doesn't match this video.** '我们把它跟乡村振兴去结合起来…' isn't in the transcript, so stage 2 prints "No period found". I used a sentence from total.srt instead, which the task asks for anyway.
4. **Bug: stage 2 crashes on any match.** It fails with `AttributeError: 'VideoClipper' object has no attribute 'lang'`, because `runner()` only sets `audio_clipper.lang` in stage 1. Patched it to set `audio_clipper.lang = lang` in stage 2.
5. **Bug: `--output_file` is ignored for video.** `video_clip()` always writes `<name>_no0.mp4`, so `res.mp4` was never created (res.srt was). Patched the CLI to move the result to `--output_file`.
6. **Models are downloaded ahead of time.** setup.sh builds the same funasr `AutoModel` (SeACo-Paraformer, FSMN-VAD, CT-punc, CAM++), so ~1.3 GB from ModelScope is cached before verification.

env.sh activates `/work/FunClip/.venv` and changes into `/work/FunClip`.
