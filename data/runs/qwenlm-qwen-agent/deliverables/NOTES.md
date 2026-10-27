# Qwen-Agent on CPU via Ollama — notes

**Ended up with:** a Python 3.12 uv venv at `/work/venv` with `pip install -e "Qwen-Agent[rag,code_interpreter,mcp,python_executor]"`. Ollama runs on CPU and serves `qwen3:1.7b` at `http://localhost:11434/v1`. `run.sh` starts `ollama serve`, logging to `/work/server.log`, and blocks until a warm-up `/v1/chat/completions` request succeeds.

## What broke following the README
1. **Missing deps after `pip install -e ./"[...]"`:** `import qwen_agent` failed with `No module named 'soundfile'` (imported by `qwen_agent/utils/utils.py`). After that it failed on `tqdm` (imported unconditionally by `qwen_agent/tools/python_executor.py`). Neither is declared in `setup.py`, so I installed `soundfile` and `tqdm` by hand.
2. **The code_interpreter tool now requires Docker:** the README says Docker is needed. The tool runs `docker info` in `__init__` and starts its Jupyter kernel in a container. This sandbox has no Docker and can't run a Docker daemon (no CAP_SYS_ADMIN).
   - **Patch:** `patches/apply_local_kernel_fallback.py`, applied by `setup.sh`. If Docker is unavailable, or `QWEN_AGENT_CODE_INTERPRETER_LOCAL=1` is set (which `env.sh` does), the tool falls back to a local Jupyter kernel subprocess. This is the pre-Docker behaviour from before commit 9fe749d.
   - **Packages:** I installed the packages the Docker image would have supplied (ipykernel, matplotlib, pandas, seaborn, sympy, openpyxl, …) into the venv.
   - **Not sandboxed:** the local kernel runs code directly on the host.
3. **`CodeInterpreter.call()` crashed on dict params:** passing `{'code': ...}` raised a TypeError, even though the signature says `Union[str, dict]`. The same patch file makes it accept dicts.
4. **Model server is up to you:** the README only links to the Qwen2 docs for Ollama. `setup.sh` installs Ollama with the official script (which needs `zstd` from apt) and pulls `qwen3:1.7b`.

## Verified
- `Assistant(llm={'model':'qwen3:1.7b','model_server':'http://localhost:11434/v1','api_key':'EMPTY'})` answers chat messages.
- With `function_list=['code_interpreter']`, it called the tool and got 123*456 = 56088.
- `CodeInterpreter().call({'code':'print(6*7)'})` returns `42`.
