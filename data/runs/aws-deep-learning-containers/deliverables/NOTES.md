# Notes

Doc followed: docs/llama-cpp/deployment/ec2.md (CPU x86, `docker run public.ecr.aws/deep-learning-containers/llama-cpp:server-cpu-v1 --hf-repo ggml-org/Qwen2.5-0.5B-Instruct-GGUF --hf-file qwen2.5-0.5b-instruct-q4_0.gguf --ctx-size 4096`).

What broke / what I changed:
1. **No Docker in the sandbox.** Built llama.cpp `llama-server` from source at the same pinned ref as
   `docker/llama_cpp/Dockerfile.cpu` (b29c606e…, v0.4.1 / b10964) using the same cmake flags
   (GGML_NATIVE=OFF, GGML_CPU_ALL_VARIANTS=ON, GGML_BACKEND_DL=ON, GGML_OPENMP=ON).
2. **System packages:** apt `cmake`, `libssl-dev`, `libgomp1` (the Dockerfile uses dnf on Amazon Linux).
   Built with `-DLLAMA_CURL=OFF`; the model is downloaded ahead of time instead of using `--hf-repo`.
3. **The documented model repo can't be fetched:** `ggml-org/Qwen2.5-0.5B-Instruct-GGUF` gets HTTP 401
   from Hugging Face (it doesn't exist publicly or is gated). setup.sh tries it first, then falls back
   to the official `Qwen/Qwen2.5-0.5B-Instruct-GGUF`, which has the same `qwen2.5-0.5b-instruct-q4_0.gguf`.
4. The server runs as `llama-server --model /work/models/qwen2.5-0.5b-instruct-q4_0.gguf --ctx-size 4096 --host 0.0.0.0 --port 8080`.
   run.sh polls /health the same way the doc does.

Verified: /health returns 200, and /v1/chat/completions answers sensibly (e.g. "The capital of France is Paris...").
