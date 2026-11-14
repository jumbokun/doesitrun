# Qwen-Agent on CPU via Ollama — notes

Followed the README: `pip install -e ./"[gui,rag,code_interpreter,mcp]"` (in a uv venv with Python 3.12 at /work/venv),
then served `qwen3:1.7b` with Ollama (OpenAI-compatible API at http://localhost:11434/v1).

What broke / what I changed:
- **Missing dependency:** `import qwen_agent` failed with `ModuleNotFoundError: No module named 'soundfile'`.
  `qwen_agent/utils/utils.py` imports `soundfile` at the top level, but `setup.py` doesn't declare it. Fixed with `pip install soundfile`.
- **Ollama installer needs zstd:** `curl -fsSL https://ollama.com/install.sh | sh` stops with "This version requires zstd". Fixed with `apt-get install zstd`.
- **Model service setup isn't spelled out:** the README only links to the Qwen2 docs for Ollama. I had to work out the steps myself: install Ollama, run `ollama serve` by hand (there's no systemd in the container) and `ollama pull qwen3:1.7b`.
  `run.sh` starts `ollama serve` in the background and sends a warm-up chat completion before it returns.

Verified (`tests/quickstart_test.py`, using the README Quickstart pattern with model `qwen3:1.7b`):
- plain chat works;
- the model calls a custom tool registered with `@register_tool` and uses its result;
- the model answers questions about `examples/resource/doc.pdf` through the RAG path.
Docker code_interpreter was not tested (not required).
