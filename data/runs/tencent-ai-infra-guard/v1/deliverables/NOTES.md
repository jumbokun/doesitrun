# AI-Infra-Guard / aig-infra-scan setup notes

- The infra-scan README tells you to `pip install aig-infra-scan` from PyPI. I did not use that. The task requires the fingerprint rules from the repo's `data/`, so I built the wheel from the checkout with `python scripts/publish_pypi.py build infra`, as the "Publish" section of the README describes.
- That build compiles `./cmd/cli/main.go`, so it needs Go (go.mod requires 1.23.2 or later). The base image has no Go and the README doesn't mention it. setup.sh installs Go 1.23.12 from go.dev into /usr/local/go.
- The build script runs `python -m build`, which needs the `build` package. I installed it into a uv venv at /work/venv (Python 3.12). The README doesn't mention this either.
- I installed the resulting platform wheel into the venv. It contains the Go binary plus `data/fingerprints`, `data/vuln` and `data/vuln_en` copied from the repo.
- env.sh activates the venv and adds Go to PATH.
- I made no code patches. I tested against a fake Ollama service (`/` returns "Ollama is running", `/api/version` returns the version). The output reported fingerprint `ollama` 0.1.30 plus its advisories.
