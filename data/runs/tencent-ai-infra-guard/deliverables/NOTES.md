# AI-Infra-Guard: aig-infra-scan setup notes

The README says to run `pip install aig-infra-scan`. That installs a prebuilt wheel from PyPI, which brings its own copy of the rules instead of using the repo's `data/`. Running from source needs extra steps the README leaves out:

1. **Go toolchain**: the base image has no Go. I installed Go 1.24.5 from go.dev into /work/go (go.mod requires go >= 1.23.2) and set GOTOOLCHAIN=local.
2. **Build the binary yourself**: in a source checkout, `infra-scan/aig_infra_scan/bin/` is empty. Without the binary, the `aig-infra-scan` wrapper exits with an error. I built it with `CGO_ENABLED=0 go build -o infra-scan/aig_infra_scan/bin/ai-infra-guard ./cmd/cli/main.go`, the same command `scripts/publish_pypi.py` uses, but without copying the rules into the package.
3. **Editable install**: I used `uv pip install -e infra-scan` into /work/venv (Python 3.12). Because `aig_infra_scan/data/` stays empty, `cli.rules_dir()` falls back to the repo's `data/fingerprints` and `data/vuln`. With `--lang en`, the Go side adds `_en` to the path and loads `data/vuln_en`.

No code patches were needed. Verified: a fake Ollama on 127.0.0.1:11434 (`/` returns "Ollama is running") was scanned with `--lang en --json -o result.json`, and the output listed fingerprint `ollama` version 0.1.30 plus its advisories.
