# aws-cli setup notes

Followed the README "CLI Dev Version" section on the `v2` branch:
`pip install -r requirements-dev-lock.txt && pip install -e .` -- it worked with Python 3.12.3.

Only deviation:
- The README runs bare `pip install`, but Ubuntu 24.04's system Python is "externally managed" (PEP 668),
  so a bare pip install into it is refused. I created a venv (`python3 -m venv /work/aws-cli/.venv`), which is
  what AGENTS.md recommends. env.sh activates it.

Verified: `aws --version` prints `aws-cli/2.40.3 Python/3.12.3 ... source/x86_64...`; `aws configure set/get`
round-trips with AWS_CONFIG_FILE pointing at a temp file; `aws ec2 run-instances --generate-cli-skeleton` prints valid JSON.
I skipped the optional autocompletion-index step (`scripts/gen-ac-index`) because the goal doesn't need it.
