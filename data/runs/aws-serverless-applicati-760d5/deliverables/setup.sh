#!/usr/bin/env bash
set -euo pipefail
cd /work
if [ ! -d serverless-application-model/.git ]; then
  git clone https://github.com/aws/serverless-application-model /work/serverless-application-model
fi
cd /work/serverless-application-model
git checkout -q 6e52163a
# README: python3 -m venv .venv && make init  (make init = pip install -e '.[dev]')
python3 -m venv .venv
. .venv/bin/activate
pip install -q --upgrade pip
make init
# README "Getting started" template
cat > /work/template.yaml <<'YAML'
Transform: AWS::Serverless-2016-10-31
Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Runtime: nodejs24.x
      Handler: index.handler
      InlineCode: |
        exports.handler = async (event) => {
          console.log(event);
        }
YAML
# Smoke test (dummy region/creds; no AWS calls are made for this template)
export AWS_DEFAULT_REGION=us-east-1 AWS_REGION=us-east-1 AWS_ACCESS_KEY_ID=dummy AWS_SECRET_ACCESS_KEY=dummy
python bin/sam-translate.py translate --template-file=/work/template.yaml --output-template=/work/out.json
