# gpt-oss:20b via Ollama (CPU only)

The README just says to `ollama pull gpt-oss:20b` / `ollama run gpt-oss:20b` "after installing Ollama".

What broke / what I changed:
- The official installer (`curl -fsSL https://ollama.com/install.sh | sh`) failed: "This version requires zstd for extraction". Fixed by `apt-get install zstd` (plus `pciutils` so GPU detection runs cleanly) first.
- There is no systemd in the container, so the installer can't start the service. `run.sh` runs `ollama serve` itself with nohup (log in /work/server.log) on 127.0.0.1:11434, pulls the model if it's missing, and loads it with keep_alive=-1 so the first request is fast.
- Models go in /work/ollama-models (OLLAMA_MODELS, set in env.sh). CPU-only works without other changes: the ~13 GB model fits in 15 GB of RAM, and a short answer takes about 10–30 s.

Tested: `/v1/chat/completions` "What is 2+2?" -> "4"; `/api/chat` "What is 3+5?" -> "3 + 5 = 8".
