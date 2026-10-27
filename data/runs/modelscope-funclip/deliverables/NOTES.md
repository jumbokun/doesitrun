# FunClip CLI demo on CPU — notes

Followed README "Python env install" plus the Linux CPU recipe in docs/installation.md
(Python 3.12 venv, torch/torchaudio 2.10.0 CPU wheels, then requirements.txt). The install and stage 1 worked as documented.

What broke / what I changed:
1. **`wget` isn't in the base image.** I used `curl` to download the example video instead.
2. **The README's example video doesn't match its stage-2 text.** The URL in section C
   (`.../examples/2022云栖大会_片段.mp4`) serves a 178 s clip of the opening speech, and
   '我们把它跟乡村振兴去结合起来…' never comes up in it. Stage 2 reports "No period found" and writes no mp4.
   The phrase is in `2022云栖大会_片段2.mp4` in the same HF Space. setup.sh saves that file as
   `examples/2022云栖大会_片段.mp4`. It also keeps the README-URL clip as `examples/2022云栖大会_片段_readme_url.mp4`.
3. **Stage 2 crashed once a match was found:** `AttributeError: 'VideoClipper' object has no attribute 'lang'`.
   Stage 2 creates `VideoClipper(None)` but never sets `.lang` (stage 1 does). The patch adds
   `audio_clipper.lang = lang` in `funclip/videoclipper.py` `runner()`.
4. **`--output_file ./output/res.mp4` wrote `./output/res_no0.mp4`.** `video_clip` always appends `_no{N}`, so
   the patched CLI `runner()` now renames the clip to the requested `--output_file`. The SRT was already written to `res.srt`.

Models (Paraformer-zh, FSMN-VAD, CT-punc, CAM++) are pre-downloaded from ModelScope into ~/.cache/modelscope by setup.sh.
Result: stage 1 writes output/total.srt in Chinese; stage 2 writes output/res.mp4 (about 4.6 s) and output/res.srt, all on CPU.
