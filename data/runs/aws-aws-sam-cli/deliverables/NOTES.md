# aws-sam-cli setup notes
- README only links to external install docs (brew/installer/pip from PyPI); the from-source path is in DEVELOPMENT_GUIDE.md (venv + `make init` = `pip install -e '.[dev]'`).
- Followed that path with system Python 3.12 venv, but installed `pip install -e .` (no `[dev]` extras, not needed to run `sam`; `make init` also only advertises `samdev`, but the `sam` entry point is installed too).
- Nothing broke: `sam init --no-interactive --app-template hello-world --package-type Zip --runtime python3.12 --dependency-manager pip` followed by `sam build` produced .aws-sam/build/template.yaml and HelloWorldFunction/app.py.
- env.sh activates the venv and sets SAM_CLI_TELEMETRY=0.
