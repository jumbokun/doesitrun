# HunyuanOCR-1.5 via llama.cpp (CPU) — notes

Followed README "PC-side deployment via llama.cpp" + docs/llama_cpp.md §1–4.1. It mostly worked as written.

What I had to add or change:
- `cmake` isn't in the base image, and the README doesn't say to install it. I installed it with apt (plus libssl-dev and pkg-config).
- I pinned upstream llama.cpp to commit 9183a552 (master at setup time, newer than b11103) so setup is reproducible. I built only `llama-server` and `llama-mtmd-cli` with `-DGGML_CUDA=OFF`.
- Python env (docs §2): I used CPU-only torch from the PyTorch CPU index so it doesn't pull CUDA wheels. I also installed llama.cpp's `requirements/requirements-convert_hf_to_gguf.txt`, which provides `gguf`, `sentencepiece` and so on. The docs only list huggingface_hub/transformers/torch/openai.
- Download: also excluded `dflash/*` (DFlash skipped as the task says). Weights live in `/work/llama.cpp/HunyuanOCR`.
- Conversion prints harmless warnings: transformers doesn't know `hunyuan_vl` and falls back to config.json, and "Unknown RoPE type: xdrope". The GGUFs work.
- Server runs with the exact §4.1 flags (port 8080, alias HYVL, ctx 10240, -fa on, --jinja). run.sh polls `/health` until it returns 200.

Verified: generated PNG "Hello World 2024" → /v1/chat/completions returned HTTP 200 with "Hello World 2024" (~7 s on 4 CPU cores).
