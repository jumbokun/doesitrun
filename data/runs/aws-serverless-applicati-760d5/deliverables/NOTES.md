# Notes
- Followed README: `python3 -m venv .venv && source .venv/bin/activate && make init` (Python 3.12) — installed fine.
- Saved the Getting started template as /work/template.yaml.
- `python bin/sam-translate.py translate ...` failed with `NoRegionFound: AWS Region cannot be found`.
  The README doesn't mention that a region is needed. Fix: `export AWS_DEFAULT_REGION=us-east-1` (the Makefile's test target does the same). No credentials needed.
- Output /work/out.json matches the README's "Under the hood" example (AWS::Lambda::Function MyFunction + AWS::IAM::Role MyFunctionRole).
