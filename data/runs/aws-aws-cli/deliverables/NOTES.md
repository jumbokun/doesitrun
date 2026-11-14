# AWS CLI v2 from source

Followed README "CLI Dev Version": `pip install -r requirements-dev-lock.txt` then `pip install -e .`
on the `v2` branch (the default branch). It worked as written with system Python 3.12.

Only addition: README doesn't say to make a virtualenv; Ubuntu 24.04's system Python is
externally-managed (PEP 668), so pip into it fails. Created /work/venv (as AGENTS.md suggests);
env.sh activates it. Also ran the optional `scripts/gen-ac-index --include-builtin-index` step.

Verified: `aws --version` (shows `source/`), configure set/get with AWS_CONFIG_FILE /
AWS_SHARED_CREDENTIALS_FILE temp files, `aws ec2 run-instances --generate-cli-skeleton`,
and `aws sqs list-queues --endpoint-url http://127.0.0.1:8999 --query ...` against a local stub
with dummy creds (signed Authorization header received).
