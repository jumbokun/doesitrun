# earshot setup notes

Goal: `python -m earshot doctor --load` exits 0 from `/work/earshot` with both models loaded.

## What broke following the README

Almost nothing. The README's Install section (clone -> `python -m venv .venv` -> `pip install torch`
from the PyTorch CPU index -> `pip install -e ".[mcp,llm,dev]"` -> `doctor --load`) worked as written
on the first attempt. Two gaps, both environmental rather than wrong docs:

1. **ffmpeg / ffprobe were not installed.** The README states they must be on PATH, and `doctor`
   reports `ffmpeg missing` as a *problem* (which is what makes the summary say "Problems: ..."), so
   the base image needs `apt-get install ffmpeg`. `python3-venv` is also installed explicitly so
   `python -m venv` is guaranteed to work on a minimal image.
2. **The models are fetched lazily.** On a cold cache `doctor --load` downloads ~1.1 GB from the
   Hugging Face Hub inside the run (~4-5 min here, and it prints an unauthenticated-rate-limit
   warning). It still exits 0, but to keep the verification run self-contained `setup.sh` runs the
   documented `python -m earshot doctor --fetch` first, so `--load` only reads the local cache
   (`/work/earshot/.cache/hf`). Both pinned revisions are still downloadable: CLAP
   `laion/larger_clap_general@16c8cc3` (a `refs/pr/2` safetensors-conversion commit) and AST
   `MIT/ast-finetuned-audioset-10-10-0.4593@f826b80`.

No GPU is involved: torch comes from `download.pytorch.org/whl/cpu`, and `doctor` reports
`torch_cuda_used: False`. Precision falls back to `fp32` because this CPU has no native bf16
(`native_bf16: False`) - that is the documented behaviour, not an error.

## What I changed

- Nothing in the repository itself; it is an unmodified clone of `main`.
- `setup.sh`: adds the two system packages above, then the README's own commands, then
  `doctor --fetch`, then `doctor --load` as a self-check. Dependency versions are pinned to the
  verified set (an inline `pip freeze`, torch separately as `2.14.1+cpu`) with a fallback to an
  unpinned install, since the project's own bounds are open-ended (`transformers>=4.40` resolved to
  5.20.2 and works). Re-running it is idempotent.
- `env.sh`: activates `/work/earshot/.venv` and sets `EARSHOT_HOME=/work/earshot/.cache` (the same
  value earshot derives for a source checkout) so the model cache is found from any directory.

## Verified

`setup.sh` was re-run after deleting the checkout and the pip cache; it completed with
`problems: []` and `notes: []`. Then, in a clean environment, sourcing `env.sh` and running
`python -m earshot doctor --load` from `/work/earshot` gave exit code 0 with
`clap_revision: 16c8cc3...` / `ast_revision: f826b80...`, both from `model.safetensors`.
A warm run takes ~20-50 s.
