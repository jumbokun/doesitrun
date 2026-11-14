# Source me: makes `ollama` resolvable and pins the server to localhost, CPU only.
export PATH="/usr/local/bin:$PATH"
export OLLAMA_HOST=127.0.0.1:11434
export OLLAMA_MODELS="${OLLAMA_MODELS:-/work/ollama-models}"
export CUDA_VISIBLE_DEVICES=""
export OLLAMA_KEEP_ALIVE=-1
