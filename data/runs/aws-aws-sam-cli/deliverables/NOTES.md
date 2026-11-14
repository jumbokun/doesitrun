# aws-sam-cli setup notes
- README only links to the AWS install docs (brew/installer/pip). I followed DEVELOPMENT_GUIDE.md: `python3 -m venv .venv`, then `pip install -e .` (the non-dev part of `make init`; `[dev]` extras aren't needed to run `sam`).
- System Python 3.12 works (requires >=3.10). Nothing broke.
- env.sh activates the venv and sets SAM_CLI_TELEMETRY=0 so no telemetry is sent during runs.
- Checked: `sam init --no-interactive --runtime python3.12 --app-template hello-world --package-type Zip --dependency-manager pip` followed by `sam build` produced .aws-sam/build/template.yaml and HelloWorldFunction/ with app.py and the vendored requests package.
