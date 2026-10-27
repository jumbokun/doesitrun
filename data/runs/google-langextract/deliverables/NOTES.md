# langextract + Ollama (gemma2:2b), CPU only

Following the README worked: `pip install -e .`, `ollama pull gemma2:2b`, `ollama serve`, and then the
Romeo & Juliet example with `model_id="gemma2:2b", model_url="http://localhost:11434"`. Running it returned 3
grounded extractions ("Lady Juliet", "gazed longingly", "Romeo"), and the JSONL and visualization HTML were written.
I didn't have to patch any code.

Things I did that the README doesn't say:
- Installed Ollama with the official `curl -fsSL https://ollama.com/install.sh | sh`. The README only links ollama.com.
  The installer needs `zstd` to unpack the release bundles, and that isn't in the base image, so I apt-installed it.
- There's no systemd in the container, so the installer can't start a service. `run.sh` starts `ollama serve` with
  nohup itself and logs to /work/server.log.
- `ollama pull` needs a server that's already running, so setup.sh starts the server first and then pulls.
- Created a uv venv at /work/venv (Python 3.12) and ran `uv pip install -e .` there. This is the README's
  venv + `pip install -e .` advice, just done with uv.
