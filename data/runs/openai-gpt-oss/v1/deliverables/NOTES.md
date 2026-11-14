# gpt-oss via Ollama on CPU

README path: "install Ollama, `ollama pull gpt-oss:20b`, `ollama run gpt-oss:20b`".

What broke / what I changed:
- Ollama's `install.sh` needs `zstd` to unpack the release tarball; it is not in the base image -> apt install zstd.
- The container has no systemd, so the installer cannot start the service; `ollama pull` needs a running
  server. setup.sh starts a temporary `ollama serve` to pull, run.sh starts `ollama serve` with nohup (log: /work/server.log).
- Models are stored in /work/ollama-models (OLLAMA_MODELS in env.sh); CPU forced via CUDA_VISIBLE_DEVICES="".
- run.sh warms up the model (empty generate, keep_alive 60m) so the first chat request is fast.
Verified: /api/chat "What is 2+2?" -> HTTP 200, answer "4" (~20s on 4 CPU cores, 16GB RAM).
