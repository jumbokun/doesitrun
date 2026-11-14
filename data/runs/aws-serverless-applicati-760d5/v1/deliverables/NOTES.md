# Notes

Followed README dev setup: `python3 -m venv .venv && source .venv/bin/activate && make init` (Python 3.12.3) — worked as written.
Saved the README "Getting started" template to `/work/template.yaml`, ran
`python bin/sam-translate.py translate --template-file=/work/template.yaml --output-template=/work/out.json`.

What broke: with no AWS region configured the translator fails with
`NoRegionFound: AWS Region cannot be found`. The README doesn't mention this (or document `bin/sam-translate.py` at all).
Fix: export dummy `AWS_DEFAULT_REGION=us-east-1` (plus dummy access keys for safety); no real AWS calls are made for this template.

Output `/work/out.json` contains `MyFunction` (AWS::Lambda::Function, Handler index.handler, Code.ZipFile inline code, nodejs24.x)
and `MyFunctionRole` (AWS::IAM::Role with AWSLambdaBasicExecutionRole), matching the README.
No code patches or pins needed. Repo pinned at commit 6e52163a in setup.sh.
