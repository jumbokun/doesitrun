# HunyuanOCR via llama.cpp (CPU) — notes

The path in docs/llama_cpp.md mostly works as written. Upstream llama.cpp master builds for CPU, has `draft-dflash`,
and converts the checkpoint (base + mmproj) without needing a patch. Things I had to add or change:

- **cmake missing**: the base image has no cmake, so I installed it with `apt-get install cmake` (plus libssl-dev for the server's HTTPS support).
- **Built for CPU only**: no `-DGGML_CUDA`. I built only the `llama-server` target to save time.
- **CPU torch**: `uv pip install torch` would pull the multi-GB CUDA wheel. I installed torch from the PyTorch CPU index instead.
- **Converter requirements**: I also installed llama.cpp's `requirements/requirements-convert_hf_to_gguf.txt`. The doc's package list is not obviously complete for `convert_hf_to_gguf.py`, but I did not test whether it fails without them.
- **Download location**: the doc's `--local-dir ./HunyuanOCR` would collide with the HunyuanOCR repo clone at /work/HunyuanOCR. I downloaded the weights to /work/models/HunyuanOCR instead and skipped `dflash/*` (optional).
- **Doc error**: §6 says `chat.py` reads `llama_cpp/test_assets/data.jsonl`, but that file isn't in the repo; only the `ocr/` images are there. I tested with a direct HTTP request instead.
- **Server**: started exactly as §4.1 (port 8080, alias HYVL, `-fa on --jinja`). run.sh waits until `/health` returns OK.

**Result**: I sent `ocr/0.png` with the official doc_parse prompt. It returned HTTP 200 and the correct page text. On this 2-core/4-thread CPU the request took about 480 s (prefill about 10 tok/s, decode about 8 tok/s), so clients need a long timeout.
