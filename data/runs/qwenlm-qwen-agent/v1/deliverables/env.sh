# source this file
source /work/venv/bin/activate
export OLLAMA_HOST=127.0.0.1:11434
export OPENAI_API_BASE=http://localhost:11434/v1
export QWEN_AGENT_CODE_INTERPRETER_LOCAL=1  # no Docker here; use patched local-kernel fallback
