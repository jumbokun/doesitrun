# agents-cli setup notes
- README's documented install is `uvx google-agents-cli setup`, which installs skills into coding agents (needs Node/npx) and isn't a persistent `agents-cli` on PATH. Instead installed the cloned repo (commit 6eedbdc, v1.14.0) into a uv venv at /work/venv; env.sh puts it on PATH.
- Node.js/npx isn't installed (README lists it as a prerequisite); `create` only prints a warning about skills and succeeds without it.
- `agents-cli create caveman-agent -y --skip-checks -o DIR` works offline from credentials: it logs GCE metadata-server auth failures and then succeeds, producing pyproject.toml and app/agent.py with root_agent.
- No code patches or pins were needed.
